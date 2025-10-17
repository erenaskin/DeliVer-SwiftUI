//
//  ProductRepository.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

class ProductRepository {
    private let apiService = APIService.shared
    
    /// Belirli bir kategoriye ait ürünleri getir
    func getProducts(for categoryId: Int64) async throws -> [ProductResponse] {
        try await apiService.fetchProducts(for: categoryId)
    }
    
    /// Belirli bir servise ait ürünleri getir
    func getProducts(forService serviceId: Int64) async throws -> [ProductResponse] {
        try await apiService.fetchProducts(serviceId: serviceId)
    }
    
    /// Belirli bir ürünün tüm detaylarını getir
    func getProductDetail(productId: Int64) async throws -> ProductResponse {
        try await apiService.fetchProductDetail(productId: productId)
    }
    
    /// Yardımcı: ürün için kullanılacak fiyatlandırma kaydı
    private func primaryPricing(for product: ProductResponse) -> ProductPricingResponse? {
        guard !product.pricing.isEmpty else { return nil }

        if let fixed = product.pricing.first(where: { $0.pricingType.uppercased() == "FIXED" }) {
            return fixed
        }
        return product.pricing.first
    }
    
    /// Aktif ürünleri filtrele
    func getActiveProducts(for categoryId: Int64) async throws -> [ProductResponse] {
        let products = try await getProducts(for: categoryId)
        return products.filter { $0.isActive }
    }
    
    /// İndirimli ürünleri getir
    func getDiscountedProducts(for categoryId: Int64) async throws -> [ProductResponse] {
        let products = try await getProducts(for: categoryId)
        return products.filter { product in
            guard let p = primaryPricing(for: product),
                  let salePrice = p.salePrice
            else {
                return false
            }
            return salePrice < p.basePrice
        }
    }
    
    /// Ürünleri fiyata göre sırala
    func getProductsSortedByPrice(for categoryId: Int64, ascending: Bool = true) async throws -> [ProductResponse] {
        let products = try await getProducts(for: categoryId)
        return products.sorted(by: { product1, product2 in
            let p1 = primaryPricing(for: product1)
            let p2 = primaryPricing(for: product2)
            let price1 = (p1?.salePrice ?? p1?.basePrice) ?? 0
            let price2 = (p2?.salePrice ?? p2?.basePrice) ?? 0
            return ascending ? price1 < price2 : price1 > price2
        })
    }
}
