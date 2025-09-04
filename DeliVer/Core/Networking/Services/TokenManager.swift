//
//  TokenManager.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import Foundation
import SwiftUI

// MARK: - Token Manager Service
protocol TokenManagerProtocol {
    func saveToken(_ token: String)
    func getToken() -> String?
    func removeToken()
    var isLoggedIn: Bool { get }
}

class TokenManager: TokenManagerProtocol {
    static let shared = TokenManager()
    private let keychain = "com.deliverapp.token"
    
    private init() {}
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: keychain)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: keychain)
    }
    
    func removeToken() {
        UserDefaults.standard.removeObject(forKey: keychain)
    }
    
    var isLoggedIn: Bool {
        return getToken() != nil
    }
}
