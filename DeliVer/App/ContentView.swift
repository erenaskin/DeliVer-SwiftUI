//
//  ContentView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        // authState'deki değişikliğe göre gösterilecek view'ı seç
        switch authManager.authState {
        case .initial:
            // Uygulama ilk açıldığında veya durum kontrol edilirken
            SplashView() // Veya basit bir ProgressView
            
        case .unauthenticated:
            // Kullanıcı giriş yapmamışsa
            LoginView() // Sizin Login ekranınız
            
        case .needsVerification(let email):
            // E-posta doğrulaması gerekiyorsa
            EmailVerificationView(email: email) // Sizin doğrulama ekranınız
            
        case .authenticated:
            // Kullanıcı tamamen giriş yapmışsa
            MainTabView() // MainTabView'ı burada kullanarak ana ekranı gösterin
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var cartService: CartService

    var body: some View {
        TabView {
            // ServiceView'ınız artık `fullScreenCover` ile CartView'ı açmamalı,
            // bunun yerine tab bar'daki Sepet sekmesi kullanılmalı.
            // Bu değişikliği ServiceView dosyanızda yapmanız gerekebilir.
            ServiceView()
                .tabItem {
                    Label("Hizmetler", systemImage: "square.grid.2x2")
                }
            
            // Sepet ekranı
            CartView()
                .tabItem {
                    Label("Sepet", systemImage: "cart")
                }
                .badge(cartService.cartCount > 0 ? "\(cartService.cartCount)" : nil)
        }
        .task {
            // Sekmeler göründüğünde sepet sayısını günceller.
            await cartService.fetchCartCount()
        }
    }
}


#Preview {
    // Bu önizleme, uygulamanızın ihtiyaç duyabileceği tüm environment object'leri sağlar.
    // Bu, hem ContentView'ın hem de alt görünümlerinin (LoginView, MainTabView vb.)
    // çökmeden çalışmasını sağlar.
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AuthViewModel())
        .environmentObject(CartService())
}

