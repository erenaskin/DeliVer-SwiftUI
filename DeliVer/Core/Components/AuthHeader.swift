//
//  AuthHeader.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//


import SwiftUI

// MARK: - Header Component
struct AuthHeader: View {
    let title: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: iconName)
                    .font(.system(size: 45, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(
                color: gradientColors.first?.opacity(0.4) ?? .clear,
                radius: 20,
                x: 0,
                y: 10
            )
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}