import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cartService: CartService // Değişiklik: ViewModel yerine CartService
    @Environment(\.dismiss) private var dismiss

    // Alert durumları
    @State private var showOrderSuccessAlert = false
    @State private var showOrderErrorAlert = false
    @State private var showCheckoutSheet = false
    @State private var showOrderStatus = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if cartService.isLoading {
                        ProgressView("Sepet yükleniyor...")
                    } else if let cart = cartService.cart, !cart.isEmpty {
                        List {
                            ForEach(cart.cartItems) { item in
                                CartItemRow(item: item, cartService: cartService)
                            }
                            
                            Section(header: Text("Sepet Özeti").font(.headline)) {
                                HStack {
                                    Text("Toplam Ürün")
                                    Spacer()
                                    Text("\(cart.totalItems) adet")
                                }
                                HStack {
                                    Text("Toplam Tutar")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(cartService.formatPrice(cart.totalAmount))
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        
                        Button(action: {
                            cartService.clearOrderState()
                            showCheckoutSheet = true
                        }) {
                            Text("Siparişi Tamamla")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding()
                        .disabled(cartService.isPlacingOrder)
                        
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "cart")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text(cartService.createdOrder == nil ? "Sepetiniz boş." : "Siparişiniz alındı!")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if cartService.isPlacingOrder {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView("Siparişiniz tamamlanıyor...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Sepetim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .task {
                 await cartService.fetchCart()
            }
            .onChange(of: cartService.showingOrderSuccess) { _, isSuccess in
                if isSuccess {
                    showCheckoutSheet = false
                    showOrderSuccessAlert = true
                }
            }
            .onChange(of: cartService.orderError) { _, newValue in
                if newValue != nil {
                    showOrderErrorAlert = true
                }
            }
            .sheet(isPresented: $showCheckoutSheet) {
                // CheckoutView artık environment'dan CartService'i otomatik alacak
                CheckoutView()
            }
            .sheet(isPresented: $showOrderStatus) {
                OrderStatusView()
            }
            .alert("Sipariş Başarılı! 🎉", isPresented: $showOrderSuccessAlert) {
                Button("Siparişimi Takip Et") {
                    showOrderStatus = true
                    cartService.clearOrderState()
                }
                Button("Tamam") {
                    cartService.clearOrderState()
                }
            } message: {
                if let order = cartService.createdOrder {
                    Text("Sipariş numaranız: \(order.orderNumber)\nTahmini teslimat: \(order.estimatedDeliveryFormatted)")
                } else {
                    Text("Siparişiniz başarıyla alındı.")
                }
            }
            .alert("Hata", isPresented: $showOrderErrorAlert) {
                Button("Tamam", role: .cancel) { cartService.clearOrderState() }
            } message: {
                Text(cartService.orderError ?? "Bilinmeyen bir hata oluştu.")
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartItemResponse
    let cartService: CartService
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: item.productImage ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.systemGray5)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.headline)
                    .lineLimit(1)
                
                if let variantName = item.variantName, !variantName.isEmpty {
                    Text(variantName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(item.quantity) x \(cartService.formatPrice(item.unitPrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(cartService.formatPrice(item.subtotal))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let service = CartService()
    let sampleItems = [
        CartItemResponse(id: 1, cartId: 1, productId: 101, productName: "Klasik Hamburger", productImage: "https://via.placeholder.com/60", productVariantId: nil, variantName: "Ekstra Peynirli", quantity: 2, unitPrice: 150.75, subtotal: 301.50, selectedOptions: ["Ekstra": "Peynir"], notes: "Tursusuz olsun", createdAt: "2023-10-27T12:34:56Z", updatedAt: "2023-10-27T12:34:56Z")
    ]
    service.cart = CartResponse(id: 1, userId: 1, totalAmount: 301.50, totalItems: 2, isEmpty: false, cartItems: sampleItems, createdAt: "2023-10-27T12:34:56Z", updatedAt: "2023-10-27T12:34:56Z")

    return CartView()
        .environmentObject(service)
}
