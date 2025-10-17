// Yeni dosya oluşturun: Services/CartService.swift

import Foundation

@MainActor
class CartService: ObservableObject {
    @Published var cart: CartResponse?
    @Published var cartCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Sipariş durumu için eklenen yeni @Published özellikler
    @Published var isPlacingOrder = false
    @Published var createdOrder: OrderResponse?
    @Published var orderError: String?
    @Published var showingOrderSuccess = false

    private let repository = CartRepository()
    private let orderRepository = OrderRepository() // Sipariş için eklendi
    
    init() {
        Task {
            await fetchCartCount()
        }
    }
    
    func fetchCart() async {
        isLoading = true
        errorMessage = nil
        do {
            cart = try await repository.getCart()
            cartCount = cart?.totalItems ?? 0
        } catch {
            errorMessage = error.localizedDescription
            cart = nil
            cartCount = 0
        }
        isLoading = false
    }
    
    func fetchCartCount() async {
        do {
            let currentCart = try await repository.getCart()
            self.cartCount = currentCart.totalItems
        } catch {
            print("Hata: Sepet sayısı alınamadı - \(error.localizedDescription)")
            self.cartCount = 0
        }
    }
    
    func addToCart(request: AddToCartRequest) async throws {
        let updatedCart = try await repository.addToCart(request: request)
        self.cart = updatedCart
        self.cartCount = updatedCart.totalItems
    }
    
    // CartViewModel'den taşınan sipariş oluşturma fonksiyonu
    func createOrderFromCart(
        deliveryAddress: String,
        phoneNumber: String,
        notes: String? = nil,
        paymentMethod: PaymentMethod = .CASH
    ) async -> Bool {
        isPlacingOrder = true
        orderError = nil
        createdOrder = nil
        
        let request = CreateOrderRequest(
            deliveryAddress: deliveryAddress,
            phoneNumber: phoneNumber,
            notes: notes,
            paymentMethod: paymentMethod.rawValue
        )
        
        do {
            // 1. Siparişi oluştur
            let newOrder = try await orderRepository.createOrder(request: request)
            createdOrder = newOrder
            
            // 2. Sunucudaki sepeti temizle
            _ = try await repository.clearCart()
            
            // 3. En Önemlisi: Yerel sepet durumunu temizle
            self.cart = nil
            self.cartCount = 0
            self.showingOrderSuccess = true
            
            isPlacingOrder = false
            return true
        } catch {
            orderError = error.localizedDescription
            isPlacingOrder = false
            return false
        }
    }
    
    func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "₺%.2f", value)
    }

    // Arayüz durumunu sıfırlamak için yardımcı fonksiyon
    func clearOrderState() {
        createdOrder = nil
        orderError = nil
        showingOrderSuccess = false
    }
}
