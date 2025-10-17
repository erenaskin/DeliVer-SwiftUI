import SwiftUI

struct AllOrdersView: View {
    @StateObject private var viewModel = AllOrdersViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .loading:
                    ProgressView("Siparişler yükleniyor...")
                        .frame(maxHeight: .infinity)
                case .content:
                    orderListView
                case .empty:
                    emptyStateView
                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Tüm Siparişlerim")
            .task {
                await viewModel.fetchInitialOrders()
            }
            .refreshable {
                await viewModel.fetchInitialOrders()
            }
        }
    }
    
    private var orderListView: some View {
        List(viewModel.orders) { order in
            ZStack {
                OrderRowView(order: order)
                
                // Sipariş detay sayfasına gitmek için NavigationLink
                NavigationLink(destination: OrderDetailView(order: order)) {
                    EmptyView()
                }
                .opacity(0)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .padding(.vertical, 8)
            .onAppear {
                // Listenin sonuna gelindiğinde daha fazla veri yükle
                if order == viewModel.orders.last {
                    Task {
                        await viewModel.loadMoreOrders()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Hiç Siparişiniz Yok")
                .font(.title2)
                .fontWeight(.semibold)
            Text("İlk siparişinizi verdiğinizde burada görünecektir.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text("Bir Hata Oluştu")
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Tekrar Dene") {
                Task {
                    await viewModel.fetchInitialOrders()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// Sipariş satırını temsil eden yardımcı View
struct OrderRowView: View {
    let order: OrderResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(order.orderNumber)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(order.statusEnum.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(order.statusEnum.color)
                    .clipShape(Capsule())
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sipariş Tarihi")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(order.formattedCreatedDate)
                    .font(.subheadline)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Tutar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(order.formattedTotalAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                HStack {
                    Text("Detayları Gör")
                    Image(systemName: "chevron.right")
                }
                .font(.footnote)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}



#Preview {
    AllOrdersView()
}
