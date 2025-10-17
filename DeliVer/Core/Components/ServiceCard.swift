//
//  ServiceCard.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 9.10.2025.
//

import Foundation
import SwiftUI

struct ServiceCard: View {
    let service: ServiceResponse
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    private func getIconForService(_ serviceName: String) -> String {
        switch serviceName {
        case ServiceType.tech.displayName: return "laptopcomputer"
        case ServiceType.pet.displayName: return "pawprint.fill"
        case ServiceType.water.displayName: return "drop.fill"
        case ServiceType.market.displayName: return "cart"
        case ServiceType.pharmacy.displayName: return "cross.vial"
        case ServiceType.food.displayName: return "fork.knife"
        default: return "star.fill"
        }
    }
    
    var body: some View {
        NavigationLink(
            destination: CategoryListView(
                serviceId: service.id,
                serviceName: service.name
            )
        ) {
            VStack(spacing: 12) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.08))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: getIconForService(service.name))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.9) : Color.primary)
                }
                
                // Service name
                Text(service.name)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 36)
                    .minimumScaleFactor(0.85)
                    .kerning(0.2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.15),
                                    lineWidth: 1)
                    )
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08),
                            radius: isPressed ? 2 : 8,
                            x: 0,
                            y: isPressed ? 1 : 4)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = false
                    }
                }
        )
    }
}

// Updated ServicesGrid to ensure uniform layout
struct ServicesGrid: View {
    let services: [ServiceResponse]
    let columns: [GridItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Hizmetler")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(services) { service in
                    ServiceCard(service: service)
                        .frame(maxWidth: .infinity) // Ensure cards fill available space
                }
            }
        }
    }
}
