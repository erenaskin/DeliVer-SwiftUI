import Foundation

struct EmptyResponse: Codable {}

// MARK: - Refresh Token Request Model
struct RefreshTokenRequest: Codable {
    let refreshToken: String
}


// MARK: - Network Error Types
enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case connectionError(String)
    case authenticationRequired // 401 hatası sonrası refresh de başarısız olursa
    case forbidden              // 403
    case notFound               // 404
    case serverError(statusCode: Int, message: String?) // 5xx ve diğerleri
    case decodingError(String)
    case requestFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz API adresi."
        case .invalidResponse:
            return "Sunucudan geçersiz yanıt alındı."
        case .connectionError(let message):
            return "Bağlantı sorunu: \(message)"
        case .authenticationRequired:
            return "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."
        case .forbidden:
            return "Bu işlem için yetkiniz bulunmuyor."
        case .notFound:
            return "İstenen kaynak bulunamadı."
        case .serverError(let code, let msg):
            return "Sunucu hatası (\(code)): \(msg ?? "Detay yok")."
        case .decodingError(let message):
            return "Veri çözümlenirken bir hata oluştu: \(message)"
        case .requestFailed(let message):
            return "Bir hata oluştu: \(message)"
        }
    }
}


// MARK: - Main APIService

class APIService {
    static let shared = APIService()
    private let baseURL = URL(string: "http://10.10.11.198:8080/api")!
    
    // Aynı anda birden fazla token yenileme isteğini önlemek için bir 'actor' kullanıyoruz.
    private let tokenRefresher = TokenRefresher()
    
    private init() {}
    
    /// Mevcut kullanıcının profil bilgilerini getirir. Token doğrulaması için kullanılır.
    func getCurrentUserProfile() async throws -> UserProfileResponse {
        return try await request(endpoint: "/users/me", method: "GET")
    }

    // MARK: - Service Endpoints
    
    /// Tüm servisleri getirir.
    func fetchServices() async throws -> [ServiceResponse] {
        try await request(endpoint: "/services")
    }
    
    /// Belirli bir servisin detaylarını getirir.
    func fetchServiceDetail(serviceId: Int64) async throws -> ServiceResponse {
        try await request(endpoint: "/services/\(serviceId)")
    }

    // MARK: - Product Endpoints
    
    /// Belirli bir kategoriye ait ürünleri getirir.
    func fetchProducts(for categoryId: Int64) async throws -> [ProductResponse] {
        // DOKÜMANTASYONA GÖRE GÜNCELLENDİ: /products/category/{id}
        return try await request(endpoint: "/products/category/\(categoryId)")
    }
    
    /// Belirli bir servise ait tüm ürünleri getirir.
    func fetchProducts(serviceId: Int64) async throws -> [ProductResponse] {
        // DOKÜMANTASYONA GÖRE GÜNCELLENDİ: /products/service/{id}
        return try await request(endpoint: "/products/service/\(serviceId)")
    }
    
    /// Belirli bir ürünün detaylarını getirir.
    func fetchProductDetail(productId: Int64) async throws -> ProductResponse {
        return try await request(endpoint: "/products/\(productId)")
    }
    
    // MARK: - Category Endpoints
    
    /// Belirli bir servise ait tüm kategorileri getirir.
    func fetchCategories(for serviceId: Int64) async throws -> [CategoryResponse] {
        // DOKÜMANTASYONA GÖRE DOĞRU ENDPOINT: /categories/service/{id}
        return try await request(endpoint: "/categories/service/\(serviceId)")
    }
    
    /// Belirli bir servise ait ana kategorileri (üst kategorisi olmayan) getirir.
    func fetchMainCategories(for serviceId: Int64) async throws -> [CategoryResponse] {
        // DOKÜMANTASYONA GÖRE GÜNCELLENDİ: /categories/service/{id}/root
        return try await request(endpoint: "/categories/service/\(serviceId)/root")
    }
    
    /// Belirli bir kategorinin alt kategorilerini getirir.
    func fetchSubcategories(for categoryId: Int64) async throws -> [CategoryResponse] {
        // DOKÜMANTASYONA GÖRE GÜNCELLENDİ: /categories/{id}/children
        return try await request(endpoint: "/categories/\(categoryId)/children")
    }
    
    /// Belirli bir kategorinin tüm alt kategorilerini (iç içe) getirir.
    func fetchAllSubcategories(for categoryId: Int64) async throws -> [CategoryResponse] {
        // NOT: Bu endpoint dokümantasyonda açıkça belirtilmemiştir.
        // "/children" yolunun "recursive=true" parametresini desteklediği varsayılmıştır.
        return try await request(endpoint: "/categories/\(categoryId)/children?recursive=true")
    }
    
    // MARK: - Cart Endpoints
    
    /// Kullanıcının sepetini temizler.
    func clearCart() async throws -> CartResponse {
        return try await request(endpoint: "/cart/clear", method: "DELETE")
    }
    
    // MARK: - Order Endpoints
    
    /// Giriş yapmış kullanıcının tüm siparişlerini sayfalama ile getirir.
    func fetchUserOrders(page: Int, size: Int = 20) async throws -> PaginatedOrderResponse {
        return try await request(endpoint: "/orders?page=\(page)&size=\(size)")
    }
    
    /// Belirli bir siparişin detaylarını getirir.
    func fetchOrderDetail(orderId: Int64) async throws -> OrderResponse {
        return try await request(endpoint: "/orders/\(orderId)")
    }
    
    /// Giriş yapmış kullanıcının aktif siparişlerini getirir.
    func fetchActiveOrders() async throws -> [OrderResponse] {
        return try await request(endpoint: "/orders/active")
    }

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        // Ana isteği yapmadan önce token'ın geçerliliğini kontrol et ve gerekirse yenile.
        try await tokenRefresher.refreshTokenIfNeeded()
        
        // Ana isteği oluştur.
        let request = try await buildRequest(endpoint: endpoint, method: method, body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Eğer 401 hatası alırsak (bu, token'ın sunucuda aniden geçersiz kılındığı nadir bir durum olabilir),
        // token'ı zorla yenileyip isteği bir kez daha deniyoruz.
        if httpResponse.statusCode == 401 {
            try await tokenRefresher.forceRefreshToken()
            let retriedRequest = try await buildRequest(endpoint: endpoint, method: method, body: body)
            let (retriedData, retriedResponse) = try await URLSession.shared.data(for: retriedRequest)
            return try handleResponse(data: retriedData, response: retriedResponse)
        }
        
        return try handleResponse(data: data, response: response)
    }
    
    private func buildRequest(endpoint: String, method: String, body: (any Encodable)?) async throws -> URLRequest {
        guard let url = URL(string: baseURL.absoluteString + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // TokenManager'dan access token'ı alıp ekliyoruz.
        if let token = TokenManager.shared.getAccessToken() {
             request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            // Eğer access token yoksa ve bu korumalı bir endpoint ise, sunucu 401 dönecektir.
            // Bu durum, kullanıcının hiç giriş yapmadığı veya token'ının silindiği anlamına gelir.
            // Burada hata fırlatmak, halka açık (public) endpoint'lere erişimi engelleyebilir.
            // Bu yüzden token olmadan devam edip sunucunun karar vermesine izin veriyoruz.
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        return request
    }
    
    private func handleResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw APIError.authenticationRequired
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorResponse?.message ?? "Sunucudan hata mesajı alınamadı.")
        }

        if data.isEmpty {
            if let empty = EmptyResponse() as? T {
                return empty
            } else {
                throw APIError.decodingError("Response was empty, but expected a value.")
            }
        }
        
        // *** BAŞLANGIÇ: DEĞİŞİKLİK BURADA ***
        // Eğer beklenen tip String ise ve veri bir JSON string'i olarak gelmişse
        // (örneğin "Başarılı"), onu doğrudan çözmeyi deneyelim.
        if T.self == String.self, let stringValue = String(data: data, encoding: .utf8) {
            // JSON string'leri tırnak işareti içerir ("..."), bunları temizleyelim.
            let trimmedString = stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if let result = trimmedString as? T {
                return result
            }
        }
        // *** BİTİŞ: DEĞİŞİKLİK BURADA ***

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let decodingError {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorResponse.message)
            }
            
            print("❌ Decoding Error: \(decodingError)")
            // Hata mesajına daha fazla detay ekleyelim
            let dataString = String(data: data, encoding: .utf8) ?? "Veri string'e çevrilemedi."
            print("📄 Gelen Veri: \(dataString)")
            throw APIError.decodingError("Model(\(String(describing: T.self))) çözümlenemedi: \(decodingError.localizedDescription)")
        }
    }
}

// Token yenileme işlemini yöneten ve eş zamanlılık sorunlarını çözen yardımcı actor.
private actor TokenRefresher {
    private var refreshTask: Task<Void, Error>?
    private let baseURL = URL(string: "http://10.10.11.198:8080/api")!

    func refreshTokenIfNeeded() async throws {
        // Giriş yapmamış kullanıcı için token yenileme işlemi yapma.
        guard TokenManager.shared.getRefreshToken() != nil else { return }
        
        if TokenManager.shared.isTokenExpiringSoon() {
            try await refreshToken()
        }
    }
    
    func forceRefreshToken() async throws {
        try await refreshToken()
    }

    private func refreshToken() async throws {
        // Eğer zaten devam eden bir yenileme işlemi varsa, onun bitmesini bekle.
        if let refreshTask = refreshTask {
            return try await refreshTask.value
        }

        // Yeni bir yenileme görevi başlat.
        let task = Task { () throws -> Void in
            defer { refreshTask = nil } // Görev bittiğinde kendini temizle.

            guard let refreshToken = TokenManager.shared.getRefreshToken() else {
                throw APIError.authenticationRequired
            }

            let url = baseURL.appendingPathComponent("/auth/refresh")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = RefreshTokenRequest(refreshToken: refreshToken)
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Refresh token da geçersizse, kullanıcıyı sistemden at.
                await MainActor.run { TokenManager.shared.clearTokens() }
                throw APIError.authenticationRequired
            }

            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            await MainActor.run {
                TokenManager.shared.saveTokens(
                    accessToken: authResponse.token,
                    refreshToken: authResponse.refreshToken,
                    expiresIn: authResponse.expiresIn
                )
            }
        }
        
        self.refreshTask = task
        return try await task.value
    }
}
