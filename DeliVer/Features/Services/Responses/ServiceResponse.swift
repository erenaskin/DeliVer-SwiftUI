//
//  ServiceResponse.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

// MARK: - ServiceResponse
struct ServiceResponse: Identifiable, Codable {
    let id: Int64
    let name: String
    let description: String?
    let iconUrl: String?
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case iconUrl = "icon_url"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.iconUrl = try container.decodeIfPresent(String.self, forKey: .iconUrl)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}