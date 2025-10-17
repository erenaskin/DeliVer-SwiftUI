import Foundation
import SwiftUI

// MARK: - Request Models

/// Sepetten sipariş oluşturmak için sunucuya gönderilecek model.
/// POST /api/orders
struct CreateOrderRequest: Codable {
    let deliveryAddress: String
    let phoneNumber: String
    let notes: String?
    let paymentMethod: String
}

/// Sipariş durumunu güncellemek (iptal etmek) için kullanılacak model.
/// PUT /api/orders/{orderId}/status
struct UpdateOrderStatusRequest: Codable {
    let orderStatus: String
}

// MARK: - Response Models

/// Sayfalama ile sipariş listesi için wrapper model
struct PaginatedOrderResponse: Codable {
    let content: [OrderResponse]
    let totalElements: Int
    let totalPages: Int
    let size: Int
    let number: Int
    let first: Bool
    let last: Bool
    let empty: Bool
}

/// Sunucudan dönen sipariş ana nesnesi.
struct OrderResponse: Codable, Identifiable, Equatable, Hashable {
    let id: Int64
    let orderNumber: String
    let orderStatus: String
    let paymentStatus: String
    let totalAmount: Double
    let deliveryAddress: String
    let phoneNumber: String
    let notes: String?
    let estimatedDeliveryTime: String?          // <- optional yapıldı
    let actualDeliveryTime: String?
    let createdAt: String
    let updatedAt: String
    let orderItems: [OrderItemResponse]
    let userId: Int64?                          // <- optional yapıldı (Admin için)
    let userEmail: String?                      // <- optional yapıldı (Admin için)
    
    // UI Helper Properties
    var statusEnum: OrderStatus {
        OrderStatus(rawValue: orderStatus) ?? .PENDING
    }
    
    var paymentStatusEnum: PaymentStatus {
        PaymentStatus(rawValue: paymentStatus) ?? .PENDING
    }
    
    var formattedTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: totalAmount)) ?? String(format: "₺%.2f", totalAmount)
    }
    
    var formattedCreatedDate: String {
        // "2025-10-09T14:40:03.338872" formatından daha okunabilir hale çevir
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        if let date = dateFormatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd MMM yyyy, HH:mm"
            displayFormatter.locale = Locale(identifier: "tr_TR")
            return displayFormatter.string(from: date)
        }
        
        return createdAt // Fallback
    }
    
    var estimatedDeliveryFormatted: String {
        guard let estimatedDeliveryTime else { return "—" }
        
        let dateFormatter = DateFormatter()
        // Backend bazen mikrosaniyesiz gelebilir; iki formatı da deneyelim
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ]
        for f in formats {
            dateFormatter.dateFormat = f
            if let date = dateFormatter.date(from: estimatedDeliveryTime) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "dd MMM yyyy, HH:mm"
                displayFormatter.locale = Locale(identifier: "tr_TR")
                return displayFormatter.string(from: date)
            }
        }
        return estimatedDeliveryTime // Fallback
    }
}

/// Sipariş içindeki her bir ürünü temsil eden model.
struct OrderItemResponse: Codable, Identifiable, Equatable, Hashable {
    let id: Int64
    let productId: Int64
    let productName: String
    let productDescription: String?
    let variantId: Int64?
    let variantName: String?
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double
    let selectedOptions: String? // Bu bir JSON string'i olabilir, gerekirse parse edilebilir
    let specialNotes: String?
    let createdAt: String
    
    // UI Helper Properties
    var formattedUnitPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: unitPrice)) ?? String(format: "₺%.2f", unitPrice)
    }
    
    var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: totalPrice)) ?? String(format: "₺%.2f", totalPrice)
    }
}

// MARK: - Enums and Helpers

/// API'den gelen sipariş durumlarını temsil eden enum.
enum OrderStatus: String, Codable, CaseIterable {
    case PENDING
    case CONFIRMED
    case PREPARING
    case OUT_FOR_DELIVERY
    case DELIVERED
    case CANCELLED

    var displayName: String {
        switch self {
        case .PENDING: return "Onay Bekliyor"
        case .CONFIRMED: return "Onaylandı"
        case .PREPARING: return "Hazırlanıyor"
        case .OUT_FOR_DELIVERY: return "Yola Çıktı"
        case .DELIVERED: return "Teslim Edildi"
        case .CANCELLED: return "İptal Edildi"
        }
    }
    
    var color: Color {
        switch self {
        case .PENDING: return .orange
        case .CONFIRMED: return .blue
        case .PREPARING: return .yellow
        case .OUT_FOR_DELIVERY: return .purple
        case .DELIVERED: return .green
        case .CANCELLED: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .PENDING: return "clock.fill"
        case .CONFIRMED: return "checkmark.circle.fill"
        case .PREPARING: return "chef.hat.fill"
        case .OUT_FOR_DELIVERY: return "car.fill"
        case .DELIVERED: return "checkmark.seal.fill"
        case .CANCELLED: return "xmark.circle.fill"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .PENDING, .CONFIRMED, .PREPARING, .OUT_FOR_DELIVERY:
            return true
        case .DELIVERED, .CANCELLED:
            return false
        }
    }
}

/// Ödeme durumları
enum PaymentStatus: String, Codable, CaseIterable {
    case PENDING
    case PAID
    case FAILED
    case REFUNDED
    
    var displayName: String {
        switch self {
        case .PENDING: return "Beklemede"
        case .PAID: return "Ödendi"
        case .FAILED: return "Başarısız"
        case .REFUNDED: return "İade Edildi"
        }
    }
    
    var color: Color {
        switch self {
        case .PENDING: return .orange
        case .PAID: return .green
        case .FAILED: return .red
        case .REFUNDED: return .blue
        }
    }
}

/// Ödeme yöntemleri
enum PaymentMethod: String, CaseIterable {
    case CASH
    case CARD
    case ONLINE
    
    var displayName: String {
        switch self {
        case .CASH: return "Nakit"
        case .CARD: return "Kredi Kartı"
        case .ONLINE: return "Online Ödeme"
        }
    }
}
