import SwiftUI

struct ServiceView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = ServiceListViewModel()
    @StateObject private var orderViewModel = OrderViewModel()
    
    // State to control the presentation of the OrderStatusView
    @State private var showingOrderStatus = false
    
    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 22) {
                    AddressSection()
                    
                    if viewModel.isLoading {
                        ProgressView("Yükleniyor...")
                            .frame(maxWidth: .infinity)
                    } else if let error = viewModel.error {
                        Text("Hata: \(error)")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    } else {
                        ServicesGrid(services: viewModel.services, columns: columns)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Add the order status button to the top-right corner of the navigation bar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingOrderStatus = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: orderViewModel.hasActiveOrders() ? "bag.fill" : "bag")
                                .foregroundColor(orderViewModel.hasActiveOrders() ? .orange : .primary)
                            
                            if orderViewModel.hasActiveOrders() {
                                Text("\(orderViewModel.activeOrders.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Circle().fill(Color.red))
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingOrderStatus) {
                OrderStatusView()
            }
            .task {
                await viewModel.fetchServices()
                await orderViewModel.fetchOrders()
            }
            .refreshable {
                await viewModel.fetchServices()
                await orderViewModel.fetchOrders()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ServiceView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            ServiceView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
