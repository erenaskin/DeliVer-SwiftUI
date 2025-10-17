//
//  CustomTextField.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import SwiftUI

// MARK: - Custom Text Field Component
struct CustomTextField: View {
    let title: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    let isSecure: Bool
    @State private var showPassword = false
    let validationColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, placeholder: String, icon: String, text: Binding<String>, isSecure: Bool = false, validationColor: Color = .clear) {
        self.title = title
        self.placeholder = placeholder
        self.icon = icon
        self._text = text
        self.isSecure = isSecure
        self.validationColor = validationColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 20)
                
                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                        .textContentType(isSecure ? .password : .emailAddress)
                } else {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none)
                        .keyboardType(icon == "envelope" ? .emailAddress : .default)
                        .textContentType(isSecure ? .password : .emailAddress)
                }
                
                if isSecure {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
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
                                    colors: validationColor == .clear ? [.orange.opacity(0.3), .yellow.opacity(0.3)] : [validationColor, validationColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: colorScheme == .dark ? .orange.opacity(0.1) : .yellow.opacity(0.05),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
    }
}
