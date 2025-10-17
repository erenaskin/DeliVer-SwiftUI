//
//  ProductResponseCard.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 8.10.2025.
//

import SwiftUI
import Foundation


// MARK: - Product Card for ProductResponse
struct ProductResponseCard: View {
    let product: ProductResponse
    let currentPrice: Double
    let originalPrice: Double
    let hasDiscount: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Image
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
                
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                } placeholder: {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                        .opacity(0.6)
                }
            }
            .frame(height: 100)
            
            // Name
            Text(product.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .minimumScaleFactor(0.9)
            
            // Price
            VStack(spacing: 2) {
                if hasDiscount, originalPrice > currentPrice {
                    Text(formatPrice(originalPrice, currency: getPricingCurrency(for: product)))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
                
                Text(formatPrice(currentPrice, currency: getPricingCurrency(for: product)))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .padding(10)
        .frame(width: 160, height: 190)
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
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func formatPrice(_ value: Double, currency: String?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let code = (currency ?? "TRY").uppercased()
        formatter.currencyCode = code
        if code == "TRY" {
            formatter.locale = Locale(identifier: "tr_TR")
        }
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "₺%.2f", value)
    }
    
    private func getPricingCurrency(for product: ProductResponse) -> String? {
        let picked = product.pricing.first(where: { $0.pricingType.uppercased() == "FIXED" }) ?? product.pricing.first
        return picked?.currency
    }
}
