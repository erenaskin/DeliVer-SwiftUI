import Foundation

class CartRepository {
    private let apiService = APIService.shared
    
    /// Bir ürünü sepete ekler.
    func addToCart(request: AddToCartRequest) async throws -> CartResponse {
        return try await apiService.request(endpoint: "/cart/add", method: "POST", body: request)
    }
    
    /// Kullanıcının mevcut sepetini getirir.
    func getCart() async throws -> CartResponse {
        return try await apiService.request(endpoint: "/cart")
    }
    
    /// Sepetteki bir ürünün miktarını günceller.
    func updateCartItemQuantity(cartItemId: Int64, quantity: Int) async throws -> CartResponse {
        let requestBody = ["quantity": quantity]
        return try await apiService.request(endpoint: "/cart/items/\(cartItemId)", method: "PUT", body: requestBody)
    }

    /// Sepeti checkout ederek siparişi tamamlar.
    func completeOrder() async throws -> OrderConfirmationResponse {
        return try await apiService.request(endpoint: "/cart/checkout", method: "POST")
    }
    
    /// Kullanıcının sepetini sunucudan temizler.
    func clearCart() async throws -> CartResponse {
        try await apiService.clearCart()
    }
}
