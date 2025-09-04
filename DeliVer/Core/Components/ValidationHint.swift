//
//  ValidationHintView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//


import SwiftUI

// MARK: - Validation Text Component
struct ValidationHint: View {
    let message: String
    let isError: Bool
    
    var body: some View {
        if !message.isEmpty {
            HStack {
                Image(systemName: isError ? "xmark.circle.fill" : "info.circle.fill")
                    .foregroundColor(isError ? .red : .orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(isError ? .red : .orange)
                Spacer()
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}
