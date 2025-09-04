//
//  LoginView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI

// MARK: - LoginView (MVVM)
struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    // Navigation state
    @State private var goToRegister = false
    @State private var goToEmailVerification = false
    
    init(viewModel: AuthViewModel? = nil) {
        if let vm = viewModel {
            _viewModel = StateObject(wrappedValue: vm)
        } else {
            _viewModel = StateObject(wrappedValue: AuthViewModel())
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)
                        
                        VStack(spacing: 40) {
                            // Header
                            AuthHeader(
                                title: "Giriş Yap",
                                subtitle: "Hesabınıza giriş yapın",
                                iconName: "person.circle.fill",
                                gradientColors: [.red, .orange, .yellow]
                            )
                            
                            // Form
                            VStack(spacing: 24) {
                                CustomTextField(
                                    title: "E-posta",
                                    placeholder: "ornek@email.com",
                                    icon: "envelope.fill",
                                    text: $viewModel.email,
                                    validationColor: viewModel.emailValidationColor
                                )
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                
                                CustomTextField(
                                    title: "Şifre",
                                    placeholder: "Şifrenizi girin",
                                    icon: "lock.fill",
                                    text: $viewModel.password,
                                    isSecure: true,
                                    validationColor: viewModel.passwordValidationColor
                                )
                                
                                ErrorMessage(message: viewModel.errorMessage)
                            }
                            
                            // Login Button
                            GradientButton(
                                title: "Giriş Yap",
                                icon: "arrow.right.circle.fill",
                                isLoading: viewModel.isLoading,
                                isDisabled: !viewModel.isLoginFormValid,
                                action: {
                                    Task {
                                        await viewModel.login()
                                        if viewModel.isAuthenticated {
                                            goToEmailVerification = true
                                        }
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 60)
                        
                        // Bottom Navigation
                        VStack(spacing: 12) {
                            Text("Henüz hesabınız yok mu?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Kayıt Ol") {
                                viewModel.clearForm()
                                goToRegister = true
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
            .navigationDestination(isPresented: $goToRegister) {
                RegisterView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $goToEmailVerification) {
                EmailVerificationView(viewModel: viewModel)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.light)
            .previewDisplayName("Login - Light")
        
        LoginView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Login - Dark")
    }
}
