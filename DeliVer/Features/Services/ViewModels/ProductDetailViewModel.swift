//
//  ProductDetailViewModel.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

@MainActor
class ProductDetailViewModel: ObservableObject {
    @Published var product: ProductResponse?
    @Published var isLoading = false
    @Published var error: String?
    
    // Seçimler
    @Published var selectedVariant: ProductVariantResponse?
    @Published var selectedOptions: [Int64: OptionValueResponse] = [:]
    @Published var quantity: Int = 1
    
    // Sepet işlemi sonucunu View'e bildirmek için
    @Published var cartUpdateResult: Result<CartResponse, APIError>?
    
    private let productRepository = ProductRepository()
    private let cartRepository = CartRepository() // Yeni repository'miz
    
    init() {}
    
    // MARK: - Pricing selection (unified)
    /// Ürün için kullanılacak fiyatlandırma kaydı:
    /// 1) pricingType == "FIXED" öncelik
    /// 2) Yoksa ilk kayıt
    private func primaryPricing(for product: ProductResponse?) -> ProductPricingResponse? {
        guard let list = product?.pricing, !list.isEmpty else { return nil }
        if let fixed = list.first(where: { $0.pricingType.uppercased() == "FIXED" }) {
            return fixed
        }
        return list.first
    }
    
    // MARK: - Public Methods
    func fetchProductDetail(productId: Int64) async {
        isLoading = true
        error = nil
        
        do {
            product = try await productRepository.getProductDetail(productId: productId)
            setupDefaultSelections()
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = "Bilinmeyen bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Cart Operations
    func addToCart() async {
        guard let product = product else {
            cartUpdateResult = .failure(.requestFailed("Ürün bilgisi bulunamadı."))
            return
        }

        // Seçili opsiyonları API'nin beklediği [String: String] formatına çeviriyoruz.
        // [GrupID: OptionValue] -> [GrupAdı: OptionAdı]
        let optionsPayload: [String: String] = Dictionary(uniqueKeysWithValues: selectedOptions.compactMap { groupId, optionValue in
            guard let groupName = product.optionGroups.first(where: { $0.id == groupId })?.name else {
                return nil
            }
            return (groupName, optionValue.name)
        })

        let request = AddToCartRequest(
            productId: product.id,
            productVariantId: selectedVariant?.id,
            quantity: quantity,
            selectedOptions: optionsPayload.isEmpty ? nil : optionsPayload,
            notes: nil // Henüz not için bir UI elemanı yok
        )

        do {
            let updatedCart = try await cartRepository.addToCart(request: request)
            cartUpdateResult = .success(updatedCart)
        } catch let apiError as APIError {
            cartUpdateResult = .failure(apiError)
        } catch {
            cartUpdateResult = .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    func selectVariant(_ variant: ProductVariantResponse) {
        selectedVariant = variant
    }
    
    func selectOption(_ option: OptionValueResponse, for groupId: Int64) {
        selectedOptions[groupId] = option
    }
    
    func increaseQuantity() {
        if let maxQuantity = primaryPricing(for: product)?.maxOrderQuantity {
            if quantity < maxQuantity {
                quantity += 1
            }
        } else {
            quantity += 1
        }
    }
    
    func decreaseQuantity() {
        let minQuantity = primaryPricing(for: product)?.minOrderQuantity ?? 1
        if quantity > minQuantity {
            quantity -= 1
        }
    }
    
    // MARK: - Computed Properties
    var totalPrice: Double {
        guard let basePricing = primaryPricing(for: product) else { return 0 }
        var basePrice = basePricing.salePrice ?? basePricing.basePrice
        
        if let variant = selectedVariant,
           let additionalPrice = variant.additionalPrice {
            basePrice += additionalPrice
        }
        for option in selectedOptions.values {
            if let additionalPrice = option.additionalPrice {
                basePrice += additionalPrice
            }
        }
        return basePrice * Double(quantity)
    }
    
    var originalTotalPrice: Double {
        guard let basePricing = primaryPricing(for: product) else { return 0 }
        var basePrice = basePricing.basePrice
        
        if let variant = selectedVariant,
           let additionalPrice = variant.additionalPrice {
            basePrice += additionalPrice
        }
        for option in selectedOptions.values {
            if let additionalPrice = option.additionalPrice {
                basePrice += additionalPrice
            }
        }
        return basePrice * Double(quantity)
    }
    
    var hasDiscount: Bool {
        guard let p = primaryPricing(for: product), let salePrice = p.salePrice else {
            return false
        }
        return salePrice < p.basePrice
    }
    
    var discountAmount: Double {
        originalTotalPrice - totalPrice
    }
    
    var discountPercentage: Double? {
        let original = originalTotalPrice
        let current = totalPrice
        guard original > 0, current < original else { return nil }
        return (original - current) / original * 100.0
    }
    
    var isValidConfiguration: Bool {
        guard let product = product else { return false }
        for group in product.optionGroups.filter({ $0.isRequired && $0.isActive }) {
            if selectedOptions[group.id] == nil {
                return false
            }
        }
        return true
    }
    
    var isQuantityValid: Bool {
        if let p = primaryPricing(for: product) {
            if let minQuantity = p.minOrderQuantity, quantity < minQuantity { return false }
            if let maxQuantity = p.maxOrderQuantity, quantity > maxQuantity { return false }
        }
        return quantity > 0
    }
    
    var canAddToCart: Bool {
        isValidConfiguration && isQuantityValid && quantity > 0
    }
    
    // MARK: - Helper Methods
    private func setupDefaultSelections() {
        guard let product = product else { return }

        if let variants = product.variants, !variants.isEmpty {
            selectedVariant = variants.first
        }

        for group in product.optionGroups.filter({ $0.isActive }) {
            if let options = group.options,
               let defaultOption = options.first(where: { $0.isDefault && $0.isActive }) {
                selectedOptions[group.id] = defaultOption
            }
        }
        
        quantity = primaryPricing(for: product)?.minOrderQuantity ?? 1
    }
    
    func resetSelections() {
        setupDefaultSelections()
    }
    
    func getActiveOptions(for group: OptionGroupResponse) -> [OptionValueResponse] {
        group.options?.filter { $0.isActive } ?? []
    }
    
    func hasSelection(for groupId: Int64) -> Bool {
        selectedOptions[groupId] != nil
    }
    
    func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let currencyCode = primaryPricing(for: product)?.currency ?? "TRY"
        formatter.currencyCode = currencyCode
        if currencyCode.uppercased() == "TRY" {
            formatter.locale = Locale(identifier: "tr_TR")
        }
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "₺%.2f", value)
    }
}
