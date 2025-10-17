//
//  ProductFlagResponse.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

// MARK: - ProductFlagResponse
struct ProductFlagResponse: Identifiable, Codable {
    let id: Int64
    let productId: Int64
    let flagType: String
    let flagValue: String?
    let displayText: String?
    let color: String?
    let iconUrl: String?
    let isActive: Bool
    let startDate: String?
    let endDate: String?
    let sortOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId
        case flagType = "flagKey"      // Düzeltildi: JSON'da "flagKey" olarak geliyor
        case flagValue
        case displayText = "description" // Düzeltildi: JSON'da "description" olarak geliyor
        case color
        case iconUrl
        case isActive
        case startDate
        case endDate
        case sortOrder
    }
}
