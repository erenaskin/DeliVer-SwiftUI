//
//  OptionGroupResponse.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

// MARK: - OptionGroupResponse
struct OptionGroupResponse: Identifiable, Codable {
    let id: Int64
    let productId: Int64?
    let name: String
    let description: String?
    let isRequired: Bool
    let selectionType: String // "single", "multiple"
    let minSelections: Int?
    let maxSelections: Int?
    let sortOrder: Int?
    let isActive: Bool
    let options: [OptionValueResponse]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId // Corrected: Changed from "product_id" to match the JSON
        case name, description
        case isRequired = "is_required"
        case selectionType = "selection_type"
        case minSelections = "min_selections"
        case maxSelections = "max_selections"
        case sortOrder = "sort_order"
        case isActive = "is_active"
        
        // İki olası anahtar adını da kontrol etmek için
        case options
        case optionValues
    }
    
    // Backend bazen "optionType" döndürebilir; ikisini de destekleyelim
    private enum AltKeys: String, CodingKey {
        case optionType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let alt = try? decoder.container(keyedBy: AltKeys.self)
        
        self.id = try container.decode(Int64.self, forKey: .id)
        self.productId = try container.decodeIfPresent(Int64.self, forKey: .productId)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.isRequired = try container.decodeIfPresent(Bool.self, forKey: .isRequired) ?? false
        
        // selectionType: önce ana key, yoksa alternatif key
        if let v = try container.decodeIfPresent(String.self, forKey: .selectionType) {
            self.selectionType = v
        } else if let v = try alt?.decodeIfPresent(String.self, forKey: .optionType) {
            self.selectionType = v
        } else {
            self.selectionType = "single"
        }
        
        // min/max seçim sayıları bazen String dönebilir, esnek olalım
        if let min = try? container.decode(Int.self, forKey: .minSelections) {
            self.minSelections = min
        } else if let minStr = try? container.decode(String.self, forKey: .minSelections),
                  let minInt = Int(minStr) {
            self.minSelections = minInt
        } else {
            self.minSelections = nil
        }
        
        if let max = try? container.decode(Int.self, forKey: .maxSelections) {
            self.maxSelections = max
        } else if let maxStr = try? container.decode(String.self, forKey: .maxSelections),
                  let maxInt = Int(maxStr) {
            self.maxSelections = maxInt
        } else {
            self.maxSelections = nil
        }
        
        self.sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        
        // *** ÇÖKME SORUNUNU ÇÖZEN KISIM ***
        // Hem "options" hem de "optionValues" anahtarını kontrol et
        if let opts = try container.decodeIfPresent([OptionValueResponse].self, forKey: .options) {
            self.options = opts
        } else if let opts = try container.decodeIfPresent([OptionValueResponse].self, forKey: .optionValues) {
            self.options = opts
        } else {
            self.options = nil
        }
    }
    
    // Encodable'ı manuel olarak ekleyerek tutarlılığı sağlıyoruz.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(productId, forKey: .productId) // Encode with camelCase
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isRequired, forKey: .isRequired)
        try container.encode(selectionType, forKey: .selectionType)
        try container.encodeIfPresent(minSelections, forKey: .minSelections)
        try container.encodeIfPresent(maxSelections, forKey: .maxSelections)
        try container.encodeIfPresent(sortOrder, forKey: .sortOrder)
        try container.encode(isActive, forKey: .isActive)
        // Veriyi "options" anahtarı ile yaz
        try container.encodeIfPresent(options, forKey: .options)
    }
}

// MARK: - OptionValueResponse
struct OptionValueResponse: Identifiable, Codable {
    let id: Int64
    let optionGroupId: Int64
    let name: String
    let description: String?
    let additionalPrice: Double?
    let imageUrl: String?
    let isDefault: Bool
    let isActive: Bool
    let sortOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case optionGroupId // camelCase
        case optionGroupId_snake = "option_group_id" // snake_case
        case name, description
        case additionalPrice = "additional_price"
        case imageUrl = "image_url"
        case isDefault = "is_default"
        case isActive = "is_active"
        case sortOrder = "sort_order"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int64.self, forKey: .id)
        
        // Handle both 'optionGroupId' and 'option_group_id'
        if let ogid = try container.decodeIfPresent(Int64.self, forKey: .optionGroupId) {
            self.optionGroupId = ogid
        } else if let ogid = try container.decodeIfPresent(Int64.self, forKey: .optionGroupId_snake) {
            self.optionGroupId = ogid
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.optionGroupId,
                .init(codingPath: container.codingPath, debugDescription: "Missing key 'optionGroupId' or 'option_group_id'")
            )
        }

        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Ek fiyat flexible olsun
        if let price = try? container.decode(Double.self, forKey: .additionalPrice) {
            self.additionalPrice = price
        } else if let priceString = try? container.decode(String.self, forKey: .additionalPrice) {
            self.additionalPrice = Double(priceString.replacingOccurrences(of: ",", with: "."))
        } else {
            self.additionalPrice = nil
        }
        
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        self.sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(optionGroupId, forKey: .optionGroupId) // Use camelCase for consistency
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(additionalPrice, forKey: .additionalPrice)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(sortOrder, forKey: .sortOrder)
    }
}
