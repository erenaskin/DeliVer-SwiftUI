//
//  EmailVerificationView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI

// MARK: - Main Email Verification View
struct EmailVerificationView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    
    let email: String
    
    @State private var code = ""
    @State private var goToHome = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    
                    VStack(spacing: 40) {
                        // Header
                        AuthHeader(
                            title: "E-posta Doğrula",
                            subtitle: "E-postanıza gönderilen kodu girin",
                            iconName: "envelope.badge.fill",
                            gradientColors: [.orange, .red, .pink]
                        )
                        
                        // Current Email Display
                        VStack(spacing: 8) {
                            Text("Doğrulama kodu gönderildi:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(email)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        // Form
                        VStack(spacing: 24) {
                            CodeInputField(code: $code)
                            
                            ErrorMessage(message: viewModel.errorMessage)
                            SuccessMessage(message: viewModel.successMessage)
                        }
                        
                        VStack(spacing: 20) {
                            // Doğrula butonu - hem confirm hem login yapacak
                            GradientButton(
                                title: "Doğrula ve Giriş Yap",
                                icon: "checkmark.shield.fill",
                                isLoading: viewModel.isLoading,
                                isDisabled: code.isEmpty,
                                action: {
                                    Task {
                                        await viewModel.confirmEmailAndLogin(verificationCode: code)
                                        // Başarılıysa HomeView’a yönlendir
                                        if viewModel.isAuthenticated {
                                            goToHome = true
                                        }
                                    }
                                }
                            )
                            
                            Button("Kodu Tekrar Gönder") {
                                Task {
                                    await viewModel.resendVerificationCode()
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 60)
                    
                    // Bottom Navigation
                    VStack(spacing: 12) {
                        Text("Başka e-posta kullanmak mı istiyorsunuz?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Geri Dön") {
                            viewModel.clearForm()
                            dismiss()
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    .padding(.bottom, 40)
                    
                    // Gizli NavigationLink: HomeView’a geçiş
                    NavigationLink(
                        destination: ServiceView(),
                        isActive: $goToHome
                    ) { EmptyView() }
                }
            }
            .frame(minHeight: geometry.size.height)
        }
        .onAppear {
            viewModel.email = email
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .animation(.easeInOut(duration: 0.3), value: viewModel.successMessage)
        .navigationBarHidden(true)
        // Emniyet: isAuthenticated true olduğunda otomatik Home’a geç
        .onChange(of: viewModel.isAuthenticated) { _, newValue in
            if newValue {
                goToHome = true
            }
        }
    }
}

struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmailVerificationView(email: "ornek@email.com")
                .environmentObject(AuthViewModel())
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            EmailVerificationView(email: "ornek@email.com")
                .environmentObject(AuthViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
