//
//  PasswordResetVew.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI

// MARK: - Password Reset View
struct PasswordResetView: View {
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var successMessage = ""
    @Environment(\.colorScheme) var colorScheme
    
    var onResetSent: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)
                        
                        VStack(spacing: 40) {
                            // Header
                            AuthHeader(
                                title: "Şifremi Unuttum",
                                subtitle: "Şifre sıfırlama bağlantısı göndereceğiz",
                                iconName: "key.horizontal.fill",
                                gradientColors: [.red, .orange, .yellow]
                            )
                            
                            // Info Card
                            InfoCard(
                                title: "Nasıl çalışır?",
                                description: "E-posta adresinizi girin, size güvenli bir şifre sıfırlama bağlantısı gönderelim.",
                                icon: "info.circle.fill"
                            )
                            
                            // Form
                            VStack(spacing: 24) {
                                CustomTextField(
                                    title: "E-posta Adresi",
                                    placeholder: "ornek@email.com",
                                    icon: "envelope.fill",
                                    text: $email,
                                    validationColor: getEmailValidationColor()
                                )
                                
                                ErrorMessage(message: errorMessage)
                                SuccessMessage(message: successMessage)
                            }
                            
                            VStack(spacing: 20) {
                                GradientButton(
                                    title: "Sıfırlama Bağlantısı Gönder",
                                    icon: "paperplane.fill",
                                    isLoading: isLoading,
                                    isDisabled: !isFormValid(),
                                    action: resetPassword
                                )
       
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 60)
                    }
                }
            }
            .frame(minHeight: geometry.size.height)
        }
        .animation(.easeInOut(duration: 0.3), value: errorMessage)
        .animation(.easeInOut(duration: 0.3), value: successMessage)
    }
    
    private func getEmailValidationColor() -> Color {
        if email.isEmpty { return .clear }
        return (email.contains("@") && email.contains(".")) ? .green : .orange
    }
    
    private func isFormValid() -> Bool {
        return !email.isEmpty && email.contains("@") && email.contains(".")
    }
    
    func resetPassword() {
        guard !email.isEmpty else {
            withAnimation(.spring()) {
                errorMessage = "E-posta adresi gereklidir"
                successMessage = ""
            }
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            withAnimation(.spring()) {
                errorMessage = "Geçerli bir e-posta adresi giriniz"
                successMessage = ""
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                isLoading = false
                successMessage = "Şifre sıfırlama bağlantısı e-postanıza gönderildi!"
                onResetSent?()
            }
        }
    }
}

struct PasswordResetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PasswordResetView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            PasswordResetView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
