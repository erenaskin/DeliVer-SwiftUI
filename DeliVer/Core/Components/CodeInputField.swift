//
//  CodeInputField.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//


import SwiftUI

// MARK: - Code Input Component
struct CodeInputField: View {
    @Binding var code: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Doğrulama Kodu")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                TextField("6 haneli kod", text: $code)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .fontWeight(.bold)
                    .textContentType(.oneTimeCode)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        colorScheme == .dark
                        ? Color.black.opacity(0.3)
                        : Color.white
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: code.isEmpty ? [.orange.opacity(0.3), .red.opacity(0.3)] : [.green, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: colorScheme == .dark ? .orange.opacity(0.1) : .orange.opacity(0.05),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
    }
}