//
//  ProductListViewModel.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

@MainActor
class ProductListViewModel: ObservableObject {
    @Published var products: [ProductResponse] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""
    
    private let repository = ProductRepository()
    private var currentCategoryId: Int64?
    
    // Filtreleme özellikleri
    @Published var showOnlyDiscounted = false
    @Published var sortOrder: SortOrder = .none
    @Published var priceRange: ClosedRange<Double> = 0...1000
    
    enum SortOrder: String, CaseIterable {
        case none = "Varsayılan"
        case priceAscending = "Fiyat: Düşükten Yükseğe"
        case priceDescending = "Fiyat: Yüksekten Düşüğe"
        case nameAscending = "İsim: A-Z"
        case nameDescending = "İsim: Z-A"
    }
    
    init() {}
    
    // MARK: - Public Methods
    func fetchProducts(for categoryId: Int64) async {
        currentCategoryId = categoryId
        isLoading = true
        error = nil
        
        do {
            // Assuming this repository method exists. If not, replace with appropriate call.
            products = try await repository.getProducts(for: categoryId)
            updatePriceRange()
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = "Bilinmeyen bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshProducts() async {
        guard let categoryId = currentCategoryId else { return }
        await fetchProducts(for: categoryId)
    }
    
    // MARK: - Computed
    var filteredAndSortedProducts: [ProductResponse] {
        var result = products
        
        if !searchText.isEmpty {
            result = result.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.description?.localizedCaseInsensitiveContains(searchText) == true ||
                product.shortDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        if showOnlyDiscounted {
            result = result.filter { hasDiscount(for: $0) }
        }
        
        result = result.filter { product in
            let price = getCurrentPrice(for: product)
            return priceRange.contains(price)
        }
        
        switch sortOrder {
        case .none:
            result.sort { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
        case .priceAscending:
            result.sort { getCurrentPrice(for: $0) < getCurrentPrice(for: $1) }
        case .priceDescending:
            result.sort { getCurrentPrice(for: $0) > getCurrentPrice(for: $1) }
        case .nameAscending:
            result.sort { $0.name < $1.name }
        case .nameDescending:
            result.sort { $0.name > $1.name }
        }
        return result
    }
    
    var discountedProductsCount: Int {
        products.filter { hasDiscount(for: $0) }.count
    }
    
    // MARK: - Corrected Helper Methods
    
    /// Finds the primary pricing record for a product.
    private func primaryPricing(for product: ProductResponse) -> ProductPricingResponse? {
        guard !product.pricing.isEmpty else { return nil }
        if let fixed = product.pricing.first(where: { $0.pricingType.uppercased() == "FIXED" }) {
            return fixed
        }
        return product.pricing.first
    }
    
    /// Gets the current display price (sale price if available, otherwise base price).
    func getCurrentPrice(for product: ProductResponse) -> Double {
        guard let pricing = primaryPricing(for: product) else { return 0.0 }
        return pricing.salePrice ?? pricing.basePrice
    }
    
    /// Gets the original price, which is always the base price.
    func getOriginalPrice(for product: ProductResponse) -> Double? {
        // Only return an original price if there's a discount, to match old logic.
        guard hasDiscount(for: product), let pricing = primaryPricing(for: product) else {
            return nil
        }
        return pricing.basePrice
    }
    
    /// Calculates the discount percentage if the product is on sale.
    func getDiscountPercentage(for product: ProductResponse) -> Double? {
        guard hasDiscount(for: product),
              let pricing = primaryPricing(for: product),
              let salePrice = pricing.salePrice,
              pricing.basePrice > 0 else {
            return nil
        }
        return ((pricing.basePrice - salePrice) / pricing.basePrice) * 100
    }
    
    /// Checks if a product has a valid discount.
    func hasDiscount(for product: ProductResponse) -> Bool {
        guard let pricing = primaryPricing(for: product), let salePrice = pricing.salePrice else {
            return false
        }
        // A discount is valid only if the sale price is lower than the base price.
        return salePrice < pricing.basePrice
    }
    
    private func updatePriceRange() {
        let prices = products.map { getCurrentPrice(for: $0) }
        if !prices.isEmpty {
            let minPrice = prices.min() ?? 0
            let maxPrice = prices.max() ?? 1000
            // Ensure minPrice is not greater than maxPrice
            priceRange = min(minPrice, maxPrice)...maxPrice
        }
    }
    
    func resetFilters() {
        searchText = ""
        showOnlyDiscounted = false
        sortOrder = .none
        updatePriceRange()
    }
}
