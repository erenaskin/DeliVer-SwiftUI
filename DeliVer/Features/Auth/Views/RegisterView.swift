//
//  RegisterView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI

// MARK: - RegisterView (MVVM)
struct RegisterView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
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
                            title: "Kayıt Ol",
                            subtitle: "Yeni hesabınızı oluşturun",
                            iconName: "person.badge.plus.fill",
                            gradientColors: [.red, .orange, .yellow]
                        )
                        
                        // Form
                        VStack(spacing: 24) {
                            // Username Field
                            VStack(spacing: 8) {
                                CustomTextField(
                                    title: "Kullanıcı Adı",
                                    placeholder: "Kullanıcı adınız",
                                    icon: "person.fill",
                                    text: $viewModel.username,
                                    validationColor: viewModel.usernameValidationColor
                                )
                                
                                ValidationHint(
                                    message: viewModel.usernameHint,
                                    isError: !viewModel.username.isEmpty && !viewModel.isUsernameValid
                                )
                            }
                            
                            // Email Field
                            CustomTextField(
                                title: "E-posta",
                                placeholder: "ornek@email.com",
                                icon: "envelope.fill",
                                text: $viewModel.email,
                                validationColor: viewModel.emailValidationColor
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            
                            // Password Field
                            VStack(spacing: 8) {
                                CustomTextField(
                                    title: "Şifre",
                                    placeholder: "Şifrenizi girin",
                                    icon: "lock.fill",
                                    text: $viewModel.password,
                                    isSecure: true,
                                    validationColor: viewModel.passwordValidationColor
                                )
                                
                                ValidationHint(
                                    message: viewModel.passwordHint,
                                    isError: !viewModel.password.isEmpty && !viewModel.isPasswordValid
                                )
                            }
                            
                            // Confirm Password Field
                            VStack(spacing: 8) {
                                CustomTextField(
                                    title: "Şifre Tekrar",
                                    placeholder: "Şifrenizi tekrar girin",
                                    icon: "lock.rectangle.fill",
                                    text: $viewModel.confirmPassword,
                                    isSecure: true,
                                    validationColor: viewModel.confirmPasswordValidationColor
                                )
                                
                                ValidationHint(
                                    message: viewModel.confirmPasswordHint,
                                    isError: !viewModel.confirmPassword.isEmpty && !viewModel.isConfirmPasswordValid
                                )
                            }
                            
                            ErrorMessage(message: viewModel.errorMessage)
                            SuccessMessage(message: viewModel.successMessage)
                        }
                        
                        // Register Button
                        GradientButton(
                            title: "Hesap Oluştur",
                            icon: "person.badge.plus.fill",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isRegisterFormValid,
                            action: {
                                Task {
                                    await viewModel.register()
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 60)
                    
                    // Bottom Navigation
                    VStack(spacing: 12) {
                        Text("Zaten hesabınız var mı?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Giriş Yap") {
                            viewModel.clearForm()
                            dismiss() // Doğrudan LoginView’e geri dön
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
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
        // Kayıt başarılı olduğunda VM 2 sn sonra shouldNavigateToLogin = true yapıyor.
        // Bu değişikliği yakalayıp geri dönüyoruz.
        .onChange(of: viewModel.shouldNavigateToLogin) { _, newValue in
            if newValue {
                dismiss()
                viewModel.shouldNavigateToLogin = false
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterView()
                .environmentObject(AuthViewModel())
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Register - Light")
        
        NavigationStack {
            RegisterView()
                .environmentObject(AuthViewModel())
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Register - Dark")
    }
}
