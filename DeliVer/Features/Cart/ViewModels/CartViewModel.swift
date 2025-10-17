import Foundation

@MainActor
class CartViewModel: ObservableObject {
    @Published var cart: CartResponse?
    @Published var isLoading = false
    @Published var error: String?
    
    // Sipariş tamamlama durumu için
    @Published var isPlacingOrder = false
    @Published var orderConfirmation: OrderConfirmationResponse?
    @Published var orderError: String?
    
    // Yeni Order entegrasyonu
    @Published var createdOrder: OrderResponse?
    @Published var showingOrderSuccess = false
    
    private let cartRepository = CartRepository()
    private let orderRepository = OrderRepository()
    
    // Değişiklik: Başlangıçta sepet nesnesi almayı zorunlu kılmıyoruz.
    // Bu, View'in ViewModel'i kolayca oluşturup veriyi sonradan çekmesini sağlar.
    // Preview'ların çalışması için `previewCart` parametresini ekliyoruz.
    init(previewCart: CartResponse? = nil) {
        self.cart = previewCart
    }
    
    func fetchCart() async {
        // Eğer preview için veri varsa, yeniden yükleme yapma.
        if cart != nil && ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        
        isLoading = true
        error = nil
        do {
            cart = try await cartRepository.getCart()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // Yeni Order API entegrasyonu
    func createOrderFromCart(
        deliveryAddress: String,
        phoneNumber: String,
        notes: String? = nil,
        paymentMethod: PaymentMethod = .CASH
    ) async -> Bool {
        isPlacingOrder = true
        orderError = nil
        orderConfirmation = nil
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
            
            // 2. Sipariş başarılıysa, sepeti sunucudan temizle
            do {
                _ = try await cartRepository.clearCart()
            } catch {
                // Sepeti temizleme başarısız olursa logla, ama işlemi durdurma
                // çünkü sipariş zaten oluşturuldu.
                print("⚠️ UYARI: Sipariş oluşturuldu ancak sepet temizlenemedi: \(error.localizedDescription)")
            }
            
            // 3. UI'daki sepeti temizle ve başarı durumunu ayarla
            cart = nil
            showingOrderSuccess = true
            
            isPlacingOrder = false
            return true
        } catch {
            orderError = error.localizedDescription
            isPlacingOrder = false
            return false
        }
    }
    
    // Eski completeOrder fonksiyonu (legacy)
    func completeOrder() async {
        isPlacingOrder = true
        orderError = nil
        orderConfirmation = nil
        
        do {
            let confirmation = try await cartRepository.completeOrder()
            orderConfirmation = confirmation
            // Sipariş sonrası sepeti temizlemek için boş bir sepet ataması yapılabilir
            // veya fetchCart() ile güncel (boş) sepet çekilebilir.
            cart = nil
        } catch {
            orderError = error.localizedDescription
        }
        
        isPlacingOrder = false
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
    
    // Helper methods
    func clearOrderState() {
        createdOrder = nil
        orderConfirmation = nil
        orderError = nil
        showingOrderSuccess = false
    }
    
    func updateQuantity(for item: CartItemResponse, newQuantity: Int) async {
        // Eğer miktar 1'den küçükse, bu genellikle ürünü silme anlamına gelir.
        // Backend'iniz 0 miktarını silme olarak algılamıyorsa, bu isteği göndermemek daha iyi olabilir.
        // Şimdilik 1'den küçük miktarları göndermiyoruz.
        guard newQuantity > 0 else {
            print("Miktar 0'dan büyük olmalıdır. Ürünü silmek için ayrı bir fonksiyon kullanılmalıdır.")
            // Gerekirse burada ürünü silme fonksiyonunu çağırabilirsiniz.
            return
        }

        isLoading = true
        error = nil
        
        do {
            // Repository'deki yeni fonksiyonu çağırıyoruz.
            let updatedCart = try await cartRepository.updateCartItemQuantity(cartItemId: item.id, quantity: newQuantity)
            
            // Başarılı olursa, ViewModel'deki sepeti güncelliyoruz.
            self.cart = updatedCart
        } catch {
            // Hata durumunda kullanıcıyı bilgilendiriyoruz.
            self.error = "Miktar güncellenemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
