import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    
    var body: some View {
        Group {
            if auth.isAuthenticated {
                ServiceView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: auth.isAuthenticated)
        .transition(.opacity)
    }
}
