import Foundation

// MARK: - Request Models

/// Sepete ürün eklemek için kullanılan model.
struct AddToCartRequest: Codable {
    let productId: Int64
    let productVariantId: Int64?
    let quantity: Int
    let selectedOptions: [String: String]?
    let notes: String?
}

// MARK: - Response Models

/// API'den dönen sepet objesi.
struct CartResponse: Codable, Identifiable, Equatable {
    let id: Int64
    let userId: Int64
    let totalAmount: Double
    let totalItems: Int
    let isEmpty: Bool
    let cartItems: [CartItemResponse]
    let createdAt: String
    let updatedAt: String
}

/// Sepet içindeki her bir ürünü temsil eden model.
struct CartItemResponse: Codable, Identifiable, Equatable {
    let id: Int64
    let cartId: Int64
    let productId: Int64
    let productName: String
    let productImage: String?
    let productVariantId: Int64?
    let variantName: String?
    let quantity: Int
    let unitPrice: Double
    let subtotal: Double
    let selectedOptions: [String: String]?
    let notes: String?
    let createdAt: String
    let updatedAt: String
}

/// Sipariş tamamlama (checkout) işlemi başarılı olduğunda dönen yanıt modeli.
struct OrderConfirmationResponse: Codable, Equatable {
    let orderId: String
    let message: String
    let estimatedDeliveryTime: String
}
