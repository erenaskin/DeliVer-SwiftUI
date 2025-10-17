//
//  ProductCard.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct ProductCard: View {
    let product: Product
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Detay sayfası açılacak (ileride yapılacak)
        }) {
            VStack(spacing: 8) {
                // Görsel Alanı
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.15),
                                    Color.blue.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: product.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                }
                .frame(height: 100)
                
                // Ürün Adı
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .minimumScaleFactor(0.9)
                
                // Fiyat
                Text("₺\(String(format: "%.2f", product.price))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
            }
            .padding(10)
            .frame(width: 150, height: 180) // daha küçük boy
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.08),
                radius: isPressed ? 2 : 6,
                x: 0, y: isPressed ? 1 : 3
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
