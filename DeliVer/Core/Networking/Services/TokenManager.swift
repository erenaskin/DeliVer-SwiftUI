import Foundation
import Security

// MARK: - Token Manager Service Protocol
protocol TokenManagerProtocol {
    /// Verilen token'ı Keychain'e güvenli bir şekilde kaydeder.
    func saveTokens(accessToken: String, refreshToken: String, tokenExpiry: Date)
    
    /// Keychain'de kayıtlı token'ı getirir.
    func getToken() -> String?
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func getTokenExpiry() -> Date?
    func saveTokenExpiry(_ expiry: Date)
    func saveToKeychain(key: String, value: String)
    func getFromKeychain(key: String) -> String?
    func deleteFromKeychain(key: String)
    
    
    /// Keychain'deki token'ı siler.
    func removeToken()
    func clearTokens()
    func isTokenExpiryValid() -> Bool
    func isTokenExpiringSoon() -> Bool
    
    /// Kullanıcının giriş yapıp yapmadığını token'ın varlığına göre kontrol eder.
    var isLoggedIn: Bool { get }
}


// Singleton olarak tasarlıyoruz ki uygulama genelinde tek bir yerden yönetilsin.
class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    @Published var isAuthenticated = false
    
    private let accessTokenKey = "deliver_access_token"
    private let refreshTokenKey = "deliver_refresh_token"
    private let tokenExpiryKey = "deliver_token_expiry"
    private let serviceName = "com.deliverapp.backend" // Benzersiz bir servis adı
    
    private init() {
        // Uygulama açıldığında token'ların geçerliliğini kontrol et
        self.isAuthenticated = getAccessToken() != nil && getRefreshToken() != nil
    }
    
    // MARK: - Public Properties
    
    /// Kullanıcının giriş yapıp yapmadığını token'ın varlığına göre kontrol eder.
    var isLoggedIn: Bool {
        return isAuthenticated
    }
    
    // MARK: - Public Methods
    
    /// Token'ları güvenli bir şekilde Keychain'e kaydeder.
    func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        saveToKeychain(key: accessTokenKey, value: accessToken)
        saveToKeychain(key: refreshTokenKey, value: refreshToken)
        
        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        UserDefaults.standard.set(expiryDate, forKey: tokenExpiryKey)
        
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    func getAccessToken() -> String? {
        return getFromKeychain(key: accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return getFromKeychain(key: refreshTokenKey)
    }
    
    /// Token'ın süresinin dolup dolmadığını kontrol eder. Süre dolmadan 5 dakika önce "süresi dolmuş" kabul edilir.
    func isTokenExpiringSoon() -> Bool {
        guard let expiryDate = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date else {
            return true // Saklanmış tarih yoksa, süresi dolmuş varsay.
        }
        // Sürenin dolmasına 5 dakika veya daha az kaldıysa true döner.
        return Date() >= expiryDate.addingTimeInterval(-300)
    }
    
    /// Tüm token'ları ve oturum bilgilerini temizler.
    func clearTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Compatibility Methods
    
    /// Legacy: Sadece access token kaydeder. Refresh token ve son kullanma tarihi bilgisi olmadan.
    /// Bu metodun kullanımı önerilmez, `saveTokens` tercih edilmelidir.
    func saveToken(_ token: String) {
        saveToKeychain(key: accessTokenKey, value: token)
        // Refresh token ve expiry date olmadan, bu oturum eksik kalacaktır
        // ve token yenileme çalışmayabilir. Bu yüzden eskilerini temizliyoruz.
        deleteFromKeychain(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    /// Legacy: `getAccessToken()` için bir sarmalayıcı.
    func getToken() -> String? {
        return getAccessToken()
    }
    
    /// Legacy: `clearTokens()` için bir sarmalayıcı.
    func removeToken() {
        clearTokens()
    }
    
    // MARK: - Private Keychain Methods
    
    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: serviceName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain'e kaydetme hatası: \(status)")
        }
    }
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: serviceName
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
