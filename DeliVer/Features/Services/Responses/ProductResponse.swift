//
//  ProductResponse.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

// MARK: - AttributeValue for flexible decoding
enum AttributeValue: Codable {
    case string(String)
    case stringArray([String])
    case int(Int)
    case double(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // The order of these attempts is important to distinguish Int from Double.
        if let arrayValue = try? container.decode([String].self) {
            self = .stringArray(arrayValue)
            return
        }
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
            return
        }
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
            return
        }
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }
        
        throw DecodingError.typeMismatch(AttributeValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported attribute value type. Expected String, [String], Int, Double, or Bool."))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .stringArray(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }
}


// MARK: - ProductResponse
struct ProductResponse: Identifiable, Codable {
    let id: Int64
    let name: String
    let description: String?
    let shortDescription: String?
    let imageUrl: String?
    let serviceId: Int64
    let categoryId: Int64
    let productType: String
    let sku: String?
    let isActive: Bool
    let sortOrder: Int?
    let attributes: [String: AttributeValue]?
    
    // Nested Models
    let pricing: [ProductPricingResponse]
    let variants: [ProductVariantResponse]?
    let optionGroups: [OptionGroupResponse]
    let flags: [ProductFlagResponse]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case shortDescription
        case imageUrl
        case serviceId
        case categoryId
        case productType
        case sku
        case isActive
        case sortOrder
        case attributes
        case pricing
        case variants
        case optionGroups
        case flags
    }
}

// MARK: - ProductPricingResponse
struct ProductPricingResponse: Identifiable, Codable {
    let id: Int64
    let productId: Int64
    let pricingType: String
    let basePrice: Double
    let salePrice: Double?
    let currency: String?
    let minOrderQuantity: Int?
    let maxOrderQuantity: Int?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId
        case pricingType
        case basePrice
        case salePrice
        case currency
        case minOrderQuantity
        case maxOrderQuantity
        case isActive
    }
}

// MARK: - ProductVariantResponse
struct ProductVariantResponse: Identifiable, Codable {
    let id: Int64
    let productId: Int64
    let variantName: String
    let name: String?
    let sku: String?
    let imageUrl: String?
    let isActive: Bool
    let additionalPrice: Double?
    let attributes: [String: AttributeValue]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId
        case variantName
        case name
        case sku
        case imageUrl
        case isActive
        case additionalPrice
        case attributes
    }
}
