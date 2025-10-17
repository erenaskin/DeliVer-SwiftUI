//
//  CategoryResponse.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

// MARK: - CategoryResponse
struct CategoryResponse: Identifiable, Codable {
    let id: Int64
    let name: String
    let description: String?
    let serviceId: Int64
    let parentId: Int64?
    let iconUrl: String?
    let imageUrl: String?
    let sortOrder: Int?
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?
    
    // MARK: - Manual Initializer
    // SwiftUI Preview'ları ve testler için manuel nesne oluşturmayı sağlar.
    // Özel bir init(from: Decoder) eklendiği için bu gereklidir.
    init(id: Int64, name: String, description: String?, serviceId: Int64, parentId: Int64?, iconUrl: String? = nil, imageUrl: String?, sortOrder: Int?, isActive: Bool, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.name = name
        self.description = description
        self.serviceId = serviceId
        self.parentId = parentId
        self.iconUrl = iconUrl
        self.imageUrl = imageUrl
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Codable Conformance
    // Support both snake_case and camelCase keys for compatibility
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        
        // snake_case
        case serviceId_snake = "service_id"
        case parentId_snake = "parent_id"
        case iconUrl_snake = "icon_url"
        case imageUrl_snake = "image_url"
        case sortOrder_snake = "sort_order"
        case isActive_snake = "is_active"
        case createdAt_snake = "created_at"
        case updatedAt_snake = "updated_at"
        
        // camelCase (as returned by current backend)
        case serviceId
        case parentId
        case iconUrl
        case imageUrl
        case sortOrder
        case isActive
        case createdAt
        case updatedAt
        
        // Extra fields present in API but not modeled
        case serviceName
        case key
        case icon
        case hasChildren
    }
    
    // Custom Decodable to accept both camelCase and snake_case
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // serviceId is required; accept camelCase or snake_case
        if let sid = try container.decodeIfPresent(Int64.self, forKey: .serviceId) {
            self.serviceId = sid
        } else if let sid = try container.decodeIfPresent(Int64.self, forKey: .serviceId_snake) {
            self.serviceId = sid
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.serviceId,
                .init(codingPath: container.codingPath, debugDescription: "Missing serviceId/service_id")
            )
        }
        
        // Decode both variants into temporaries, then coalesce without try on RHS
        let parentCamel = try container.decodeIfPresent(Int64.self, forKey: .parentId)
        let parentSnake = try container.decodeIfPresent(Int64.self, forKey: .parentId_snake)
        self.parentId = parentCamel ?? parentSnake
        
        let iconCamel = try container.decodeIfPresent(String.self, forKey: .iconUrl)
        let iconSnake = try container.decodeIfPresent(String.self, forKey: .iconUrl_snake)
        self.iconUrl = iconCamel ?? iconSnake
        
        let imageCamel = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        let imageSnake = try container.decodeIfPresent(String.self, forKey: .imageUrl_snake)
        self.imageUrl = imageCamel ?? imageSnake
        
        let sortCamel = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        let sortSnake = try container.decodeIfPresent(Int.self, forKey: .sortOrder_snake)
        self.sortOrder = sortCamel ?? sortSnake
        
        let activeCamel = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        let activeSnake = try container.decodeIfPresent(Bool.self, forKey: .isActive_snake)
        self.isActive = (activeCamel ?? activeSnake) ?? true
        
        let createdCamel = try container.decodeIfPresent(String.self, forKey: .createdAt)
        let createdSnake = try container.decodeIfPresent(String.self, forKey: .createdAt_snake)
        self.createdAt = createdCamel ?? createdSnake
        
        let updatedCamel = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        let updatedSnake = try container.decodeIfPresent(String.self, forKey: .updatedAt_snake)
        self.updatedAt = updatedCamel ?? updatedSnake
    }
    
    // Provide Encodable since we customized Decodable, to avoid any synthesis issues.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(serviceId, forKey: .serviceId) // write camelCase
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encodeIfPresent(iconUrl, forKey: .iconUrl)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(sortOrder, forKey: .sortOrder)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}
