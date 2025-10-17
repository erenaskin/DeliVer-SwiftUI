//
//  DeliVerApp.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI

@main
struct DeliVerApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cartService = CartService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(authViewModel)
                .environmentObject(cartService)
        }
    }
}
