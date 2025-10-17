//
//  DeliVerMarketView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct DeliVerMarketView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var orderViewModel = OrderViewModel()
    
    @State private var searchText = ""
    @State private var selectedCategory = "Tümü"
    @State private var sortOption: SortOption = .popularity
    @State private var showingOrderStatus = false
    
    private let categories = ["Tümü", "Süt Ürünleri", "Et & Balık", "Meyve & Sebze", "Fırın", "Temizlik", "Kişisel Bakım"]
    
    private let products: [Product] = [
        Product(name: "Organik Süt", description: "1 litre tam yağlı süt", price: 15.50, imageName: "drop.fill"),
        Product(name: "Taze Ekmek", description: "Günlük fırın ekmeği", price: 4.50, imageName: "leaf.fill"),
        Product(name: "Domates", description: "1 kg taze domates", price: 12.00, imageName: "leaf.circle.fill"),
        Product(name: "Tavuk Eti", description: "1 kg bonfile", price: 65.00, imageName: "fork.knife.circle.fill"),
        Product(name: "Deterjan", description: "3 kg çamaşır deterjanı", price: 45.00, imageName: "bubbles.and.sparkles.fill"),
        Product(name: "Şampuan", description: "400ml bakım şampuanı", price: 25.00, imageName: "drop.triangle.fill"),
        Product(name: "Elma", description: "1 kg kırmızı elma", price: 18.00, imageName: "apple.logo"),
        Product(name: "Peynir", description: "500g beyaz peynir", price: 35.00, imageName: "square.fill")
    ]
    
    private var filteredProducts: [Product] {
        var list = products
        if selectedCategory != "Tümü" {
            let key = selectedCategory.lowercased()
            list = list.filter { $0.name.lowercased().contains(key) || $0.description.lowercased().contains(key) }
        }
        if !searchText.isEmpty {
            let query = searchText
            list = list.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.description.localizedCaseInsensitiveContains(query) }
        }
        switch sortOption {
        case .priceLowToHigh:
            return list.sorted { $0.price < $1.price }
        case .priceHighToLow:
            return list.sorted { $0.price > $1.price }
        case .popularity:
            return list
        }
    }
    
    private let grid = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 16)]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PromoCard(
                    title: "Haftalık Fırsatlar!",
                    subtitle: "Seçili ürünlerde %30 indirim",
                    gradient: Gradient(colors: [Color.green, Color.blue]),
                    leadingIcon: "cart.fill"
                )
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category,
                                baseColor: .green
                            ) {
                                withAnimation(.snappy) { selectedCategory = category }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                SectionHeader(title: "Market Ürünleri", systemImage: "basket.fill")
                    .padding(.horizontal)
                
                if filteredProducts.isEmpty {
                    ContentUnavailableView(
                        "Ürün bulunamadı",
                        systemImage: "cart",
                        description: Text("Arama veya filtreleri düzenlemeyi deneyin")
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .padding(.horizontal)
                } else {
                    LazyVGrid(columns: grid, spacing: 16) {
                        ForEach(filteredProducts) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                
                // API Products Section
                ServiceProductListView(serviceType: .market) { product in
                    // Navigate to product detail - implement navigation logic here
                    print("Product tapped: \(product.name)")
                }
            }
            .contentMargins(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("DeliVerMarket")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Ürün ara…")
        .searchSuggestions {
            ForEach(products.prefix(6)) { item in
                Text(item.name).searchCompletion(item.name)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Order Status Button
                    Button(action: {
                        showingOrderStatus = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: orderViewModel.hasActiveOrders() ? "bag.fill" : "bag")
                                .foregroundColor(orderViewModel.hasActiveOrders() ? .orange : .primary)
                            
                            if orderViewModel.hasActiveOrders() {
                                Text("\(orderViewModel.activeOrders.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Circle().fill(Color.red))
                            }
                        }
                    }
                    
                    // Sort Menu
                    Menu {
                        Picker("Sırala", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Label(option.title, systemImage: option.icon).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .animation(.snappy, value: selectedCategory)
        .animation(.snappy, value: searchText)
        .animation(.snappy, value: sortOption)
        .background(pageBackground)
        .fullScreenCover(isPresented: $showingOrderStatus) {
            OrderStatusView()
        }
        .task {
            await orderViewModel.fetchOrders()
        }
        .refreshable {
            await orderViewModel.fetchOrders()
        }
    }
    
    private var pageBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
            ? [Color.black, Color(.sRGB, red: 0.08, green: 0.08, blue: 0.12, opacity: 1)]
            : [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Reusable bits (scoped)

private enum SortOption: CaseIterable {
    case popularity, priceLowToHigh, priceHighToLow
    var title: String {
        switch self {
        case .popularity: return "Popüler"
        case .priceLowToHigh: return "Fiyat (Artan)"
        case .priceHighToLow: return "Fiyat (Azalan)"
        }
    }
    var icon: String {
        switch self {
        case .popularity: return "star.fill"
        case .priceLowToHigh: return "arrow.down.circle"
        case .priceHighToLow: return "arrow.up.circle"
        }
    }
}

private struct CategoryChip: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    let isSelected: Bool
    let baseColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(backgroundStyle)
                .overlay(overlayStroke)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule(style: .continuous))
                .shadow(color: shadowColor, radius: isSelected ? 8 : 0, x: 0, y: isSelected ? 3 : 0)
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundStyle: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(LinearGradient(colors: [baseColor, baseColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            return AnyShapeStyle(Color(colorScheme == .dark ? .tertiarySystemBackground : .secondarySystemBackground))
        }
    }
    
    private var overlayStroke: some View {
        Capsule(style: .continuous)
            .strokeBorder(
                isSelected
                ? AnyShapeStyle(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                : AnyShapeStyle(Color(.quaternaryLabel)),
                lineWidth: isSelected ? 1.2 : 0.8
            )
    }
    
    private var shadowColor: Color {
        isSelected
        ? (colorScheme == .dark ? Color.green.opacity(0.35) : Color.green.opacity(0.25))
        : .clear
    }
}

private struct PromoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    let subtitle: String
    let gradient: Gradient
    let leadingIcon: String
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline).bold().foregroundStyle(.white)
                Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: leadingIcon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: (colorScheme == .dark ? Color.black : Color.green).opacity(colorScheme == .dark ? 0.35 : 0.15), radius: 10, x: 0, y: 6)
    }
}

private struct SectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    let systemImage: String
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                            ? [Color.green.opacity(0.35), Color.blue.opacity(0.25)]
                            : [Color.green.opacity(0.25), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }
            Text(title).font(.title3).bold()
            Spacer()
        }
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack { DeliVerMarketView() }
}
