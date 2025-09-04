//
//  NetworkService.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import Foundation
import SwiftUI

// MARK: - Network Service
protocol NetworkServiceProtocol {
    func register(request: RegisterRequest) async throws -> AuthResponse
    func login(request: LoginRequest) async throws -> AuthResponse
}

class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    private let session = URLSession.shared
    private let baseURL = "http://192.168.0.7:8080/api"
    
    private init() {}
    
    func register(request: RegisterRequest) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await session.data(for: urlRequest)
            
            return try handleResponse(data: data, response: response)
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed
        }
    }
    
    func login(request: LoginRequest) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await session.data(for: urlRequest)
            
            return try handleResponse(data: data, response: response)
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed
        }
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> AuthResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            do {
                return try JSONDecoder().decode(AuthResponse.self, from: data)
            } catch {
                throw NetworkError.decodingError
            }
        } else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message)
            } else {
                throw NetworkError.serverError("Sunucu hatası")
            }
        }
    }
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case requestFailed
    case serverError(String)
    case noInternetConnection
    case loginFailed
    case encodingError
    case emailVerificationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Sunucudan geçersiz yanıt"
        case .decodingError:
            return "Veri işleme hatası"
        case .requestFailed:
            return "İstek başarısız"
        case .serverError(let message):
            return message
        case .noInternetConnection:
            return "İnternet bağlantısı yok"
        case .loginFailed:
            return "Bilgileriniz yanlış"
        case .encodingError:
            return "Veri kodlaması hatası"
        case .emailVerificationFailed:
            return "E-posta doğrulama hatası"
        }
    }
}
