//
//  Untitled.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import Foundation

// MARK: - Error Response Model
struct ErrorResponse: Codable {
    let error: String?
    let message: String
    let status: Int?
    let timestamp: String?
    let path: String?
}
