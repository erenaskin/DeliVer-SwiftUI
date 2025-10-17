import SwiftUI

struct OrderStatusView: View {
    @StateObject private var orderViewModel = OrderViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                // Hata durumunu en önce kontrol et
                if let error = orderViewModel.error {
                    OrderErrorView(errorMessage: error) {
                        Task {
                            await orderViewModel.fetchActiveOrders()
                        }
                    }
                } else if orderViewModel.isLoading {
                    ProgressView("Siparişler Yükleniyor...")
                } else if orderViewModel.activeOrders.isEmpty {
                    // Aktif sipariş yoksa gösterilecek ekran
                    OrderEmptyStateView()
                } else {
                    // Aktif siparişler varsa listele
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(orderViewModel.activeOrders) { order in
                                OrderStatusCard(order: order)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Aktif Siparişlerim")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink("Tüm Siparişler") {
                        AllOrdersView()
                    }
                }
            }
        }
        .environmentObject(orderViewModel) // ViewModel'i tüm alt view'lara aktar
        .task {
            // Bu ekran göründüğünde aktif siparişleri çek
            if orderViewModel.activeOrders.isEmpty && orderViewModel.error == nil {
                await orderViewModel.fetchActiveOrders()
            }
        }
        .refreshable {
            await orderViewModel.fetchActiveOrders()
        }
    }
}

// Hata durumunda gösterilecek yardımcı View
struct OrderErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Bir Hata Oluştu")
                .font(.title2.bold())
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Tekrar Dene", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}


// Aktif sipariş olmadığında gösterilecek yardımcı View
struct OrderEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shippingbox")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("Aktif siparişiniz bulunmuyor")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Mevcut siparişleriniz yola çıktığında veya hazırlandığında burada görünecektir.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OrderStatusCard: View {
    let order: OrderResponse
    @EnvironmentObject private var orderViewModel: OrderViewModel
    @State private var showingDetail = false
    @State private var showingCancelAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sipariş #\(order.orderNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(order.formattedCreatedDate)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(order.formattedTotalAmount)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Status
            HStack(spacing: 12) {
                Image(systemName: order.statusEnum.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(order.statusEnum.color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(order.statusEnum.color.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.statusEnum.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(order.statusEnum.color)
                    
                    if order.statusEnum != .DELIVERED {
                        Text("Tahmini: \(order.estimatedDeliveryFormatted)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Order Items Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Sipariş İçeriği")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                ForEach(order.orderItems.prefix(2)) { item in
                    HStack {
                        Text("\(item.quantity)x")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        Text(item.productName)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(item.formattedTotalPrice)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                if order.orderItems.count > 2 {
                    Text("ve \(order.orderItems.count - 2) ürün daha...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.leading, 30)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Detayları Gör") {
                    showingDetail = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
                
                if order.statusEnum == .PENDING || order.statusEnum == .CONFIRMED {
                    Button("İptal Et") {
                        showingCancelAlert = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showingDetail) {
            OrderDetailView(order: order)
        }
        .alert("Siparişi İptal Et", isPresented: $showingCancelAlert) {
            Button("İptal", role: .cancel) { }
            Button("Evet, İptal Et", role: .destructive) {
                Task {
                    await orderViewModel.cancelOrder(order.id)
                }
            }
        } message: {
            Text("Bu siparişi iptal etmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
        }
    }
}

struct OrderDetailView: View {
    let order: OrderResponse
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Order Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sipariş Detayları")
                            .font(.system(size: 24, weight: .bold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Sipariş No:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(order.orderNumber)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            HStack {
                                Text("Tarih:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(order.formattedCreatedDate)
                                    .font(.system(size: 16))
                            }
                            
                            HStack {
                                Text("Durum:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 6) {
                                    Image(systemName: order.statusEnum.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(order.statusEnum.color)
                                    Text(order.statusEnum.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(order.statusEnum.color)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Order Items
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sipariş İçeriği")
                            .font(.system(size: 20, weight: .semibold))
                        
                        ForEach(order.orderItems) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.productName)
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        if let variantName = item.variantName {
                                            Text("Varyant: \(variantName)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if let description = item.productDescription {
                                            Text(description)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(item.quantity) adet")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                        
                                        Text(item.formattedTotalPrice)
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                
                                if item != order.orderItems.last {
                                    Divider()
                                        .padding(.top, 8)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Total
                    HStack {
                        Text("Toplam")
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                        Text(order.formattedTotalAmount)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Divider()
                    
                    // Delivery Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Teslimat Bilgileri")
                            .font(.system(size: 20, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text("Adres:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(order.deliveryAddress)
                                    .font(.system(size: 16))
                            }
                            
                            HStack {
                                Text("Telefon:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(order.phoneNumber)
                                    .font(.system(size: 16))
                            }
                            
                            if let notes = order.notes, !notes.isEmpty {
                                HStack(alignment: .top) {
                                    Text("Notlar:")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(notes)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Sipariş #\(order.orderNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct OrderHistoryCard: View {
    let order: OrderResponse
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sipariş #\(order.orderNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(order.formattedCreatedDate)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(order.formattedTotalAmount)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: order.statusEnum.icon)
                            .font(.system(size: 12))
                            .foregroundColor(order.statusEnum.color)
                        Text(order.statusEnum.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(order.statusEnum.color)
                    }
                }
            }
            
            HStack {
                Text("\(order.orderItems.count) ürün")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Detayları Gör") {
                    showingDetail = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .sheet(isPresented: $showingDetail) {
            OrderDetailView(order: order)
        }
    }
}

#Preview {
    OrderStatusView()
}
