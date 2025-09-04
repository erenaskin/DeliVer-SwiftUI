//
//  EmailVerificationView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI

// MARK: - Main Email Verification View
struct EmailVerificationView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var code = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var goToMainApp = false
    
    init(viewModel: AuthViewModel? = nil) {
        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            _viewModel = StateObject(wrappedValue: AuthViewModel())
        }
    }
    
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
                            
                            Text(viewModel.email)
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
                                        if viewModel.isAuthenticated && viewModel.successMessage.contains("başarılı") {
                                            // 1 saniye sonra ana uygulamaya geç
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                goToMainApp = true
                                            }
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
                }
            }
            .frame(minHeight: geometry.size.height)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .animation(.easeInOut(duration: 0.3), value: viewModel.successMessage)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $goToMainApp) {
            // Ana uygulama sayfanız buraya gelecek
            HomeView()
                .navigationBarBackButtonHidden(true)
        }
    }
}
struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmailVerificationView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            EmailVerificationView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
