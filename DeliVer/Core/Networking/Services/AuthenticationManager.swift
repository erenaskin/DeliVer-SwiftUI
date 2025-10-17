import Foundation
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    
    enum AuthState {
        case initial              // Uygulama ilk açıldığında, durum kontrol ediliyor
        case unauthenticated      // Giriş yapılmamış veya token geçersiz
        case needsVerification(email: String) // Giriş yapılmış ama e-posta onayı gerekli
        case authenticated        // Giriş yapılmış ve e-posta onaylanmış
    }
    
    @Published var authState: AuthState = .initial
    
    init() {
        // Uygulama açıldığında kimlik durumunu hemen kontrol et
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    func checkAuthenticationStatus() async {
        // Cihazda token yoksa, direkt olarak giriş yapılmamış say.
        guard TokenManager.shared.getAccessToken() != nil else {
            self.authState = .unauthenticated
            return
        }
        
        // Cihazda token var. Geçerliliğini ve kullanıcının durumunu sunucuda kontrol et.
        do {
            let userProfile = try await APIService.shared.getCurrentUserProfile()
            
            if userProfile.emailVerified {
                // E-posta doğrulanmışsa, kullanıcı tam olarak giriş yapmıştır.
                print("✅ Token ve e-posta doğrulandı. Kullanıcı giriş yaptı.")
                self.authState = .authenticated
            } else {
                // E-posta doğrulanmamışsa, doğrulama ekranına yönlendir.
                print("⚠️ Token geçerli ama e-posta doğrulanmamış. Doğrulama gerekli.")
                self.authState = .needsVerification(email: userProfile.email)
            }
        } catch {
            // Token geçersizse (örn. 401 Unauthorized), durumu "giriş yapılmamış" olarak ayarla.
            // APIService içindeki hata yönetimi zaten token'ları temizlemiş olmalı.
            print("❌ Token doğrulanamadı. Giriş yapılmamış duruma geçiliyor.")
            TokenManager.shared.clearTokens() // Her ihtimale karşı token'ları temizle
            self.authState = .unauthenticated
        }
    }

    /// Başarılı giriş ve doğrulama sonrası çağrılır.
    func completeAuthentication() {
        self.authState = .authenticated
    }

    /// Çıkış yapıldığında çağrılır.
    func logout() async {
        // İdeal olarak, backend'de bir logout endpoint'i çağrılır.
        // Şimdilik sadece yerel token'ları temizliyoruz.
        TokenManager.shared.clearTokens()
        self.authState = .unauthenticated
    }
}
