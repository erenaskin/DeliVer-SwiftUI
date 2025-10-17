import Foundation

struct UserProfileResponse: Codable {
    let id: Int64
    let username: String
    let email: String
    let role: String
    let emailVerified: Bool
}
