//
//  AuthResponse.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import Foundation

struct AuthResponse: Codable {
    let token: String
}

struct EmailVerificationRequest: Codable {
    let email: String
}
