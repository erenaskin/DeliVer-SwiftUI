//
//  GradientButton.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI


// MARK: - Gradient Button Component
struct GradientButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(title)
                        .fontWeight(.bold)
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isDisabled || isLoading
                            ? [.gray.opacity(0.6), .gray.opacity(0.4)]
                            : [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isDisabled || isLoading ? .clear : .orange.opacity(0.4),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
    }
}
