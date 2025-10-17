import Foundation
import SwiftUI

// MARK: - Auth ViewModel
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var isAuthenticated = false
    
    @Published var successMessage: String = ""
    @Published var shouldNavigateToLogin: Bool = false
    @Published var shouldShowEmailVerification = false
    
    // MARK: - Backend Configuration
    private let baseURL = "http://10.10.11.198:8080/api/auth"
    
    // MARK: - Init (restore session)
    init() {
        isAuthenticated = TokenManager.shared.isLoggedIn
    }
    
    // MARK: - Validation Properties
    var isUsernameValid: Bool {
        username.count >= 3 && username.count <= 50
    }
    
    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    
    var isPasswordValid: Bool {
        password.count >= 6 && password.count <= 100
    }
    
    var isConfirmPasswordValid: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var isRegisterFormValid: Bool {
        !username.isEmpty && isUsernameValid &&
        !email.isEmpty && isEmailValid &&
        !password.isEmpty && isPasswordValid &&
        !confirmPassword.isEmpty && isConfirmPasswordValid
    }
    
    var isLoginFormValid: Bool {
        !email.isEmpty && isEmailValid &&
        !password.isEmpty && isPasswordValid
    }
    
    // MARK: - Validation Colors
    var usernameValidationColor: Color {
        if username.isEmpty { return .clear }
        return isUsernameValid ? .green : .orange
    }
    
    var emailValidationColor: Color {
        if email.isEmpty { return .clear }
        return isEmailValid ? .green : .orange
    }
    
    var passwordValidationColor: Color {
        if password.isEmpty { return .clear }
        return isPasswordValid ? .green : .orange
    }
    
    var confirmPasswordValidationColor: Color {
        if confirmPassword.isEmpty { return .clear }
        return isConfirmPasswordValid ? .green : .red
    }
    
    // MARK: - Validation Hints
    var usernameHint: String {
        if !username.isEmpty && !isUsernameValid {
            return "Kullanıcı adı 3-50 karakter olmalı"
        }
        return ""
    }
    
    var passwordHint: String {
        if !password.isEmpty && !isPasswordValid {
            return "Şifre 6-100 karakter olmalı"
        }
        return ""
    }
    
    var confirmPasswordHint: String {
        if !confirmPassword.isEmpty && !isConfirmPasswordValid {
            return "Şifreler eşleşmiyor"
        }
        return ""
    }
    
    // MARK: - Auth Actions
    func register() async {
        guard isRegisterFormValid else {
            setError("Lütfen tüm alanları doğru şekilde doldurun")
            return
        }
        
        setLoading(true)
        clearError()
        clearSuccess()
        
        do {
            let request = RegisterRequest(
                username: username,
                email: email,
                password: password
            )
            
            let _ = try await performRegister(request: request)
            
            setSuccess("Hesap başarıyla oluşturuldu 🎉")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.shouldNavigateToLogin = true
            }
            
        } catch let error as NetworkError {
            setError(error.localizedDescription)
        } catch {
            setError("Beklenmeyen bir hata oluştu")
        }
        
        setLoading(false)
    }
    
    // Login: sadece doğrulama kodu gönderir; token doğrulamadan sonra alınır
    func login() async {
        guard isLoginFormValid else {
            setError("Lütfen tüm alanları doğru şekilde doldurun")
            return
        }
        
        setLoading(true)
        clearError()
        
        do {
            try await sendEmailVerification()
            shouldShowEmailVerification = true
        } catch let error as NetworkError {
            setError(error.localizedDescription)
        } catch {
            setError("Giriş veya email doğrulama başarısız")
        }
        
        setLoading(false)
    }
    
    // EmailVerificationView: hem confirm hem login yapar
    func confirmEmailAndLogin(verificationCode: String) async {
        setLoading(true)
        clearError()
        
        do {
            print("🔍 Email doğrulama başlıyor: \(email), Code: \(verificationCode)")
            
            // 1) Email doğrulamasını onayla
            try await confirmEmailVerification(code: verificationCode)
            print("✅ Email doğrulama başarılı")
            
            // 2) Login yap (token al ve kaydet)
            print("Login öncesi email: \(email)")
            guard !email.isEmpty else {
                setError("Email alanı boş! Lütfen tekrar deneyin.")
                setLoading(false)
                return
            }
            try await performLogin()
            print("✅ Login başarılı")
            
            setSuccess("Giriş başarılı! 🎉")
            shouldShowEmailVerification = false
            // isAuthenticated performLogin içinde true olur
            
        } catch let error as NetworkError {
            print("❌ Hata: \(error.localizedDescription)")
            setError(error.localizedDescription)
            isAuthenticated = false
        } catch {
            print("❌ Beklenmeyen hata: \(error)")
            setError("Beklenmeyen bir hata oluştu: \(error.localizedDescription)")
            isAuthenticated = false
        }
        
        setLoading(false)
    }

    // Kod tekrar gönderme
    func resendVerificationCode() async {
        do {
            try await sendEmailVerification()
            setSuccess("Yeni doğrulama kodu gönderildi")
        } catch {
            setError("Kod tekrar gönderilemedi")
        }
    }
    
    func logout() {
        TokenManager.shared.removeToken()
        isAuthenticated = false
        shouldShowEmailVerification = false
        shouldNavigateToLogin = false
        clearForm()
    }
    
    // MARK: - Private Network Methods
    private func performRegister(request: RegisterRequest) async throws {
        guard let url = URL(string: "\(baseURL)/register") else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return
        } else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorData.message)
            } else {
                throw NetworkError.serverError("Kayıt işlemi başarısız")
            }
        }
    }
    
    private func sendEmailVerification() async throws {
        guard let url = URL(string: "\(baseURL)/verify-email/send") else {
            throw NetworkError.invalidURL
        }
        
        let request = EmailVerificationRequest(email: email)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw NetworkError.emailVerificationFailed
        }
    }
    
    private func confirmEmailVerification(code: String) async throws {
        guard let url = URL(string: "\(baseURL)/verify-email/confirm?code=\(code)") else {
            throw NetworkError.invalidURL
        }
        
        print("🔗 URL: \(url.absoluteString)")
        print("🔢 Verification code: \(code)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📊 HTTP Status Code: \(httpResponse.statusCode)")
        
        if let responseData = String(data: data, encoding: .utf8) {
            print("📝 Backend Response: \(responseData)")
        }
        
        if httpResponse.statusCode != 200 {
            if let responseData = String(data: data, encoding: .utf8) {
                throw NetworkError.serverError("Email doğrulama başarısız: \(responseData)")
            } else {
                throw NetworkError.emailVerificationFailed
            }
        }
    }
    
    private func performLogin() async throws {
        guard let url = URL(string: "\(baseURL)/login") else {
            throw NetworkError.invalidURL
        }
        
        let loginRequest = LoginRequest(email: email, password: password)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(loginRequest)
        } catch {
            throw NetworkError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            if let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                TokenManager.shared.saveToken(authResponse.token)
                isAuthenticated = true
            }
        } else {
            if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorData.message)
            } else {
                throw NetworkError.loginFailed
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setLoading(_ loading: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = loading
        }
    }
    
    private func setError(_ message: String) {
        withAnimation(.spring()) {
            errorMessage = message
            successMessage = ""
        }
    }
    
    private func clearError() {
        errorMessage = ""
    }
    
    private func setSuccess(_ message: String) {
        withAnimation(.spring()) {
            successMessage = message
            errorMessage = ""
        }
    }
    
    private func clearSuccess() {
        successMessage = ""
    }
    
    func clearForm() {
        username = ""
        email = ""
        password = ""
        confirmPassword = ""
        clearError()
        clearSuccess()
    }
}
