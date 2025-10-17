//
//  NetworkService.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import Foundation
import SwiftUI

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    func register(request: RegisterRequest) async throws -> AuthResponse
    func login(request: LoginRequest) async throws -> AuthResponse
    func sendEmailVerification(email: String) async throws
    func confirmEmailVerification(code: String, email: String) async throws
}

// MARK: - Network Service
class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    private let session = URLSession.shared
    private let baseURL = "http://10.10.11.198:8080/api"
    private init() {}

    // --- Register ---
    func register(request: RegisterRequest) async throws -> AuthResponse {
        try await postRequest(endpoint: "/auth/register", body: request)
    }

    // --- Login ---
    func login(request: LoginRequest) async throws -> AuthResponse {
        try await postRequest(endpoint: "/auth/login", body: request)
    }

    // --- Send Email Verification ---
    func sendEmailVerification(email: String) async throws {
        let request = EmailVerificationRequest(email: email)
        let _: EmptyResponse = try await postRequest(endpoint: "/auth/verify-email/send", body: request)
    }

    // --- Confirm Email Verification ---
    func confirmEmailVerification(code: String, email: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/verify-email/confirm?code=\(code)&email=\(email)") else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = Data() // Body boş

        let (_, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        if httpResponse.statusCode != 200 {
            throw NetworkError.emailVerificationFailed
        }
    }

    // --- Generic POST Request ---
    private func postRequest<T: Encodable, U: Decodable>(endpoint: String, body: T) async throws -> U {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw NetworkError.invalidURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw NetworkError.encodingError
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        if (200...299).contains(httpResponse.statusCode) {
            if U.self == EmptyResponse.self {
                return EmptyResponse() as! U
            }
            do {
                return try JSONDecoder().decode(U.self, from: data)
            } catch {
                // Decoding hatasını konsola detaylı yazalım
                debugPrint("❌ POST \(url.absoluteString) decoding error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    debugPrint("🧾 Response body:\n\(raw)")
                }
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
    case invalidURL, invalidResponse, decodingError, requestFailed
    case serverError(String), noInternetConnection, loginFailed
    case encodingError, emailVerificationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL"
        case .invalidResponse: return "Sunucudan geçersiz yanıt"
        case .decodingError: return "Veri işleme hatası"
        case .requestFailed: return "İstek başarısız"
        case .serverError(let message): return message
        case .noInternetConnection: return "İnternet bağlantısı yok"
        case .loginFailed: return "Bilgileriniz yanlış"
        case .encodingError: return "Veri kodlaması hatası"
        case .emailVerificationFailed: return "E-posta doğrulama hatası"
        }
    }
}



// MARK: - Services API
class ServiceAPI {
    static let shared = ServiceAPI()
    private let baseURL = "http://10.10.11.198:8080/api/services"  // Servis endpoint’inizi doğrulayın
    
    private func authorizedRequest(for url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        // Eğer backend snake_case kullanıyorsa açabilirsiniz:
        // decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // Decoding hatasını detaylı logla
            debugPrint("❌ Decoding error for \(T.self): \(error)")
            if let json = String(data: data, encoding: .utf8) {
                debugPrint("🧾 Raw JSON:\n\(json)")
            }
            throw NetworkError.decodingError
        }
    }
    
    func fetchServices() async throws -> [Service] {
        guard let url = URL(string: baseURL) else { throw NetworkError.invalidURL }
        let request = authorizedRequest(for: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        
        #if DEBUG
        if let body = String(data: data, encoding: .utf8) {
            print("GET \(url.absoluteString) -> \(http.statusCode)\n\(body)")
        } else {
            print("GET \(url.absoluteString) -> \(http.statusCode)")
        }
        #endif
        
        switch http.statusCode {
        case 200...299:
            if http.statusCode == 204 { return [] }
            return try decode([Service].self, from: data)
        default:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message)
            }
            throw NetworkError.requestFailed
        }
    }
    
    func fetchServiceDetail(id: Int64) async throws -> Service {
        guard let url = URL(string: "\(baseURL)/\(id)") else { throw NetworkError.invalidURL }
        let request = authorizedRequest(for: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        
        #if DEBUG
        if let body = String(data: data, encoding: .utf8) {
            print("GET \(url.absoluteString) -> \(http.statusCode)\n\(body)")
        } else {
            print("GET \(url.absoluteString) -> \(http.statusCode)")
        }
        #endif
        
        switch http.statusCode {
        case 200...299:
            return try decode(Service.self, from: data)
        default:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message)
            }
            throw NetworkError.requestFailed
        }
    }
}
