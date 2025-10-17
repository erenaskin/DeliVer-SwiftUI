//
//  AuthRepository.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//
import SwiftUI
import Foundation

// MARK: - Network Service (Repository Pattern)
protocol AuthRepositoryProtocol {
    func register(request: RegisterRequest) async throws -> AuthResponse
    func login(request: LoginRequest) async throws -> AuthResponse
}

class AuthRepository: AuthRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }
    
    func register(request: RegisterRequest) async throws -> AuthResponse {
        return try await networkService.register(request: request)
    }
    
    func login(request: LoginRequest) async throws -> AuthResponse {
        return try await networkService.login(request: request)
    }
}
