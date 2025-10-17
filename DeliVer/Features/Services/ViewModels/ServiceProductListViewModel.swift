//
//  ServiceProductListViewModel.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 7.10.2025.
//

import Foundation
import Combine

@MainActor
class ServiceProductListViewModel: ObservableObject {
    @Published var products: [ProductResponse] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""
    
    private var allProducts: [ProductResponse] = []
    private var currentServiceType: ServiceType?
    private let repository = ProductRepository()
    private var searchCancellable: AnyCancellable?

    init() {
        // Debounce search text changes
        searchCancellable = $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterProducts(with: searchText)
            }
    }
    
    // MARK: - Pricing selection (unified)
    private func primaryPricing(for product: ProductResponse) -> ProductPricingResponse? {
        // Corrected: product.pricing is not optional, so we just check for emptiness.
        guard !product.pricing.isEmpty else { return nil }
        
        if let fixed = product.pricing.first(where: { $0.pricingType.uppercased() == "FIXED" }) {
            return fixed
        }
        return product.pricing.first
    }
    
    // MARK: - Public Methods
    func fetchProducts(for serviceType: ServiceType) async {
        currentServiceType = serviceType
        isLoading = true
        error = nil
        
        do {
            let fetchedProducts = try await repository.getProducts(forService: Int64(serviceType.rawValue))
            allProducts = fetchedProducts
            products = fetchedProducts
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
            products = []
            allProducts = []
        } catch {
            self.error = "Bilinmeyen bir hata oluştu: \(error.localizedDescription)"
            products = []
            allProducts = []
        }
        
        isLoading = false
    }
    
    func refreshProducts() async {
        if let serviceType = currentServiceType {
            await fetchProducts(for: serviceType)
        }
    }
    
    private func filterProducts(with query: String) {
        if query.isEmpty {
            products = allProducts
        } else {
            products = allProducts.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Helpers (use unified pricing)
    func getCurrentPrice(for product: ProductResponse) -> Double {
        guard let p = primaryPricing(for: product) else { return 0 }
        return p.salePrice ?? p.basePrice
    }
    
    func getOriginalPrice(for product: ProductResponse) -> Double {
        guard let p = primaryPricing(for: product) else { return 0 }
        return p.basePrice
    }
    
    func getDiscountPercentage(for product: ProductResponse) -> Double? {
        guard let p = primaryPricing(for: product),
              let salePrice = p.salePrice,
              p.basePrice > 0,
              salePrice < p.basePrice else { return nil }
              
        return ((p.basePrice - salePrice) / p.basePrice) * 100
    }
    
    func hasDiscount(for product: ProductResponse) -> Bool {
        // Corrected: A discount exists if salePrice is present and less than basePrice.
        guard let p = primaryPricing(for: product), let salePrice = p.salePrice else {
            return false
        }
        return salePrice < p.basePrice
    }
    
    func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "₺\(price)"
    }
    
    // MARK: - Computed
    var isEmpty: Bool {
        !isLoading && products.isEmpty && error == nil
    }
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
}
