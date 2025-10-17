import Foundation

// Sunucudan dönen kullanıcı bilgilerini temsil eden model.
// Bu model, AuthResponse içinde de kullanılabilir.
struct User: Codable, Identifiable {
    let id: Int64
    let username: String
    let email: String
    let role: String
    let emailVerified: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, role, emailVerified
    }
}
