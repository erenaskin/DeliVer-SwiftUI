import Foundation

class OrderRepository {
    
    private let apiService = APIService.shared

    func createOrder(request: CreateOrderRequest) async throws -> OrderResponse {
        return try await apiService.request(endpoint: "/orders", method: "POST", body: request)
    }

    func fetchOrders(page: Int = 0, size: Int = 10) async throws -> [OrderResponse] {
        let endpoint = "/orders?page=\(page)&size=\(size)"
        // Backend'in paginated veya düz array döndürme ihtimaline karşı Data olarak alıp burada çözüyoruz.
        let data: Data = try await apiService.request(endpoint: endpoint)
        
        do {
            let paginated = try JSONDecoder().decode(PaginatedOrderResponse.self, from: data)
            return paginated.content
        } catch {
            return try JSONDecoder().decode([OrderResponse].self, from: data)
        }
    }
    
    /// Kullanıcının tüm siparişlerini sayfalama desteği ile getirir.
    func getUserOrders(page: Int, size: Int = 20) async throws -> PaginatedOrderResponse {
        try await apiService.fetchUserOrders(page: page, size: size)
    }
    
    /// Belirli bir siparişin detaylarını getirir.
    func getOrderDetail(orderId: Int64) async throws -> OrderResponse {
        try await apiService.fetchOrderDetail(orderId: orderId)
    }
    
    /// Kullanıcının aktif siparişlerini getirir.
    func getActiveOrders() async throws -> [OrderResponse] {
        try await apiService.fetchActiveOrders()
    }

    func fetchActiveOrders() async throws -> [OrderResponse] {
        return try await apiService.request(endpoint: "/orders/active")
    }

    func fetchOrderById(orderId: Int64) async throws -> OrderResponse {
        return try await apiService.request(endpoint: "/orders/\(orderId)")
    }

    func fetchOrderByNumber(orderNumber: String) async throws -> OrderResponse {
        return try await apiService.request(endpoint: "/orders/by-number/\(orderNumber)")
    }

    func cancelOrder(orderId: Int64) async throws -> OrderResponse {
        let requestBody = UpdateOrderStatusRequest(orderStatus: "CANCELLED")
        return try await apiService.request(endpoint: "/orders/\(orderId)/status", method: "PUT", body: requestBody)
    }
}
