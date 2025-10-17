import Foundation
import SwiftUI
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [OrderResponse] = []
    @Published var activeOrders: [OrderResponse] = []
    @Published var currentOrder: OrderResponse?
    @Published var isLoading = false
    @Published var isLoadingActive = false
    @Published var error: String?
    @Published var successMessage: String?
    
    // Sipariş oluşturma
    @Published var isCreatingOrder = false
    @Published var createOrderError: String?
    
    // Sipariş iptal etme
    @Published var isCancellingOrder = false
    @Published var cancelOrderError: String?
    
    private let orderRepository = OrderRepository()
    private var pollingTimer: AnyCancellable?

    // ViewModel oluşturulduğunda otomatik yenilemeyi başlat
    init() {
        startPollingForActiveOrders()
    }

    // ViewModel bellekten silindiğinde otomatik yenilemeyi durdur
    @MainActor
    deinit {
        stopPollingForActiveOrders()
    }
    
    // MARK: - Sipariş Oluşturma
    func createOrder(
        deliveryAddress: String,
        phoneNumber: String,
        notes: String? = nil,
        paymentMethod: PaymentMethod = .CASH
    ) async -> Bool {
        isCreatingOrder = true
        createOrderError = nil
        successMessage = nil
        
        let request = CreateOrderRequest(
            deliveryAddress: deliveryAddress,
            phoneNumber: phoneNumber,
            notes: notes,
            paymentMethod: paymentMethod.rawValue
        )
        
        do {
            let newOrder = try await orderRepository.createOrder(request: request)
            currentOrder = newOrder
            
            // Aktif siparişleri güncelle
            await fetchActiveOrders()
            
            successMessage = "Siparişiniz başarıyla oluşturuldu! 🎉"
            isCreatingOrder = false
            return true
        } catch {
            createOrderError = error.localizedDescription
            isCreatingOrder = false
            return false
        }
    }
    
    // MARK: - Sipariş Listeleme
    func fetchOrders(page: Int = 0, size: Int = 10) async {
        if orders.isEmpty {
            isLoading = true
        }
        error = nil
        
        do {
            let fetchedOrders = try await orderRepository.fetchOrders(page: page, size: size)
            orders = fetchedOrders.sorted { $0.createdAt > $1.createdAt }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchActiveOrders() async {
        // Eğer aktif siparişler ilk defa yükleniyorsa ana `isLoading`'ı kullan,
        // değilse (polling gibi) arka plan `isLoadingActive`'i kullan.
        if activeOrders.isEmpty {
            isLoading = true
        } else {
            isLoadingActive = true
        }
        error = nil
        
        do {
            activeOrders = try await orderRepository.fetchActiveOrders()
        } catch {
            self.error = error.localizedDescription
        }
        
        // Her iki durumu da false yap
        isLoading = false
        isLoadingActive = false
    }
    
    func fetchOrderById(_ orderId: Int64) async {
        isLoading = true
        error = nil
        
        do {
            currentOrder = try await orderRepository.fetchOrderById(orderId: orderId)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchOrderByNumber(_ orderNumber: String) async {
        isLoading = true
        error = nil
        
        do {
            currentOrder = try await orderRepository.fetchOrderByNumber(orderNumber: orderNumber)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Sipariş İptal Etme
    func cancelOrder(_ orderId: Int64) async -> Bool {
        isCancellingOrder = true
        cancelOrderError = nil
        
        do {
            let updatedOrder = try await orderRepository.cancelOrder(orderId: orderId)
            
            if let index = orders.firstIndex(where: { $0.id == orderId }) {
                orders[index] = updatedOrder
            }
            
            // İptal edilen siparişi aktif listesinden kaldır
            activeOrders.removeAll { $0.id == orderId }
            
            if currentOrder?.id == orderId {
                currentOrder = updatedOrder
            }
            
            successMessage = "Sipariş başarıyla iptal edildi."
            isCancellingOrder = false
            return true
        } catch {
            cancelOrderError = error.localizedDescription
            isCancellingOrder = false
            return false
        }
    }
    
    // MARK: - Otomatik Yenileme Mantığı
    
    /// Aktif sipariş durumunu belirli aralıklarla sunucudan çekmeyi başlatır.
    func startPollingForActiveOrders(interval: TimeInterval = 30.0) {
        stopPollingForActiveOrders()
        
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }

        pollingTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                print("Aktif siparişler için durum kontrolü yapılıyor...")
                Task {
                    await self.fetchActiveOrders()
                }
            }
    }
    
    /// Aktif siparişleri yenilemeyi durdurur.
    func stopPollingForActiveOrders() {
        pollingTimer?.cancel()
        pollingTimer = nil
    }
    
    // MARK: - Helper Methods
    func clearMessages() {
        error = nil
        successMessage = nil
        createOrderError = nil
        cancelOrderError = nil
    }
    
    func hasActiveOrders() -> Bool {
        return !activeOrders.isEmpty
    }
    
    func getOrderStatusSummary() -> String {
        let activeCount = activeOrders.count
        if activeCount == 0 {
            return "Aktif sipariş bulunmuyor"
        } else if activeCount == 1 {
            return "1 aktif sipariş"
        } else {
            return "\(activeCount) aktif sipariş"
        }
    }
    
    func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "₺%.2f", value)
    }
}
