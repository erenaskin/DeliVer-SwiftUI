//
//  ExpandableCategoryView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 8.10.2025.
//

import SwiftUI

struct ExpandableCategoryView: View {
    let category: CategoryResponse
    let subcategories: [CategoryResponse]
    @Binding var selectedCategoryId: Int64?
    let onCategorySelect: (Int64?) -> Void
    
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Ana kategori butonu
            Button(action: {
                if subcategories.isEmpty {
                    // Alt kategori yoksa direkt seç
                    onCategorySelect(category.id)
                } else {
                    // Alt kategori varsa expand/collapse
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }
            }) {
                HStack(spacing: 12) {
                    // Kategori ikonu
                    ZStack {
                        Circle()
                            .fill(
                                selectedCategoryId == category.id ?
                                LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color(.systemGray5), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: getCategoryIcon(for: category.name))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedCategoryId == category.id ? .white : .primary)
                    }
                    
                    // Kategori adı ve bilgileri
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if !subcategories.isEmpty {
                            Text("\(subcategories.count) alt kategori")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Expand/Collapse ikonu
                    if !subcategories.isEmpty {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 0 : 0))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
                    }
                    
                    // Seçili göstergesi
                    if selectedCategoryId == category.id {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            selectedCategoryId == category.id ?
                            Color.orange.opacity(0.1) :
                            Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Alt kategoriler (expandable)
            if isExpanded && !subcategories.isEmpty {
                VStack(spacing: 8) {
                    ForEach(subcategories) { subcategory in
                        SubcategoryRow(
                            subcategory: subcategory,
                            isSelected: selectedCategoryId == subcategory.id,
                            onSelect: { onCategorySelect(subcategory.id) }
                        )
                    }
                }
                .padding(.leading, 56) // Ana kategori ikonunun sağından hizala
                .padding(.trailing, 16)
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }
    
    private func getCategoryIcon(for categoryName: String) -> String {
        let name = categoryName.lowercased()
        
        switch name {
        case let n where n.contains("hamburger") || n.contains("burger"):
            return "fork.knife.circle.fill"
        case let n where n.contains("pizza"):
            return "circle.grid.3x3.fill"
        case let n where n.contains("döner") || n.contains("doner"):
            return "oval.fill"
        case let n where n.contains("tavuk") || n.contains("chicken"):
            return "leaf.fill"
        case let n where n.contains("balık") || n.contains("fish"):
            return "fish.fill"
        case let n where n.contains("çorba") || n.contains("soup"):
            return "drop.circle.fill"
        case let n where n.contains("salata") || n.contains("salad"):
            return "leaf.circle.fill"
        case let n where n.contains("tatlı") || n.contains("dessert"):
            return "heart.circle.fill"
        case let n where n.contains("içecek") || n.contains("drink"):
            return "drop.fill"
        case let n where n.contains("kahve") || n.contains("coffee"):
            return "cup.and.saucer.fill"
        default:
            return "fork.knife"
        }
    }
}

// MARK: - SubcategoryRow
struct SubcategoryRow: View {
    let subcategory: CategoryResponse
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Alt kategori göstergesi
                Circle()
                    .fill(isSelected ? Color.orange : Color(.systemGray4))
                    .frame(width: 6, height: 6)
                
                // Alt kategori adı
                Text(subcategory.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .orange : .primary)
                
                Spacer()
                
                // Seçili göstergesi
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ?
                        Color.orange.opacity(0.1) :
                        Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // This helper view hosts our component and manages its state,
    // making the preview fully interactive.
    struct PreviewContainer: View {
        @State private var selectedId: Int64? = 2

        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    ExpandableCategoryView(
                        category: CategoryResponse(
                            id: 1,
                            name: "Hamburger",
                            description: "Lezzetli hamburgerler",
                            serviceId: 101,
                            parentId: nil,
                            imageUrl: nil,
                            sortOrder: 1,
                            isActive: true,
                            createdAt: nil,
                            updatedAt: nil
                        ),
                        subcategories: [
                            CategoryResponse(
                                id: 2,
                                name: "Klasik Burger",
                                description: "Geleneksel burgerler",
                                serviceId: 101,
                                parentId: 1,
                                imageUrl: nil,
                                sortOrder: 1,
                                isActive: true,
                                createdAt: nil,
                                updatedAt: nil
                            ),
                            CategoryResponse(
                                id: 3,
                                name: "Özel Burger",
                                description: "Özel tarifli burgerler",
                                serviceId: 101,
                                parentId: 1,
                                imageUrl: nil,
                                sortOrder: 2,
                                isActive: true,
                                createdAt: nil,
                                updatedAt: nil
                            )
                        ],
                        selectedCategoryId: $selectedId,
                        onCategorySelect: { id in
                            selectedId = id
                        }
                    )
                    
                    ExpandableCategoryView(
                        category: CategoryResponse(
                            id: 4,
                            name: "Pizza",
                            description: "İtalyan pizzaları",
                            serviceId: 101,
                            parentId: nil,
                            imageUrl: nil,
                            sortOrder: 2,
                            isActive: true,
                            createdAt: nil,
                            updatedAt: nil
                        ),
                        subcategories: [],
                        selectedCategoryId: $selectedId,
                        onCategorySelect: { id in
                            selectedId = id
                        }
                    )
                }
                .padding()
            }
        }
    }

    return PreviewContainer()
}
