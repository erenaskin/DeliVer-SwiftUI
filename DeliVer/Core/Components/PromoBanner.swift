//
//  PromoBanner.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 9.10.2025.
//

import SwiftUI
import Foundation

struct PromoBanner: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Toplam 450 TL İndirim!")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Her siparişte kazan")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 52, height: 52)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: colorScheme == .dark ?
                    [Color.red.opacity(0.8), Color.orange.opacity(0.8)] :
                    [Color.red, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .shadow(color: .blue.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}
