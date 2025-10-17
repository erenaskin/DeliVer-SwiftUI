//
//
//  DeliVerPetView.swift
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct DeliVerPetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var orderViewModel = OrderViewModel()

    
    @State private var searchText = ""
    @State private var selectedPetType = "Hepsi"
    @State private var sortOption: SortOption = .popularity
    @State private var showingOrderStatus = false
    
    private let petTypes = ["Hepsi", "Köpek", "Kedi", "Kuş", "Balık", "Kemirgen"]
    
    private let petProducts: [Product] = [
        Product(name: "Premium Köpek Maması", description: "Yetişkin köpekler için", price: 285.0, imageName: "house.fill"),
        Product(name: "Kedi Kumu 10L", description: "Doğal bentonit kumu", price: 45.0, imageName: "cube.fill"),
        Product(name: "Köpek Oyuncağı", description: "Çiğneme direnç oyuncak", price: 35.0, imageName: "tennisball.fill"),
        Product(name: "Kedi Taşıma Çantası", description: "Hava geçirgen güvenli", price: 199.0, imageName: "bag.fill"),
        Product(name: "Balık Yemi", description: "Tropikal balık yemi 250g", price: 28.0, imageName: "fish.fill"),
        Product(name: "Kedi Tırmık Tahtası", description: "Doğal sisal halatlı", price: 125.0, imageName: "rectangle.fill"),
        Product(name: "Köpek Tasması", description: "Ayarlanabilir deri tasma", price: 89.0, imageName: "circle.fill"),
        Product(name: "Hamster Kafesi", description: "2 katlı lüks hamster evi", price: 350.0, imageName: "house.circle.fill")
    ]
    
    private var filteredProducts: [Product] {
        var list = petProducts
        if selectedPetType != "Hepsi" {
            let key = selectedPetType.lowercased()
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
                    title: "Veteriner Danışmanlığı!",
                    subtitle: "Ücretsiz online veteriner desteği",
                    gradient: Gradient(colors: [Color.brown, Color.orange]),
                    leadingIcon: "stethoscope"
                )
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(petTypes, id: \.self) { type in
                            CategoryChip(
                                title: type,
                                isSelected: selectedPetType == type,
                                baseColor: .brown
                            ) {
                                withAnimation(.snappy) { selectedPetType = type }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                PetInfoCard(
                    leftIcon: "gift.fill",
                    leftTitle: "Özel Fırsatlar",
                    leftSubtitle: "500₺+ alışverişte ücretsiz kargo",
                    rightIcon: "heart.fill",
                    rightTitle: "Sevimli dostlarınız için!"
                )
                .padding(.horizontal)
                
                SectionHeader(title: "Pet Ürünleri", systemImage: "pawprint.fill")
                    .padding(.horizontal)
                
                if filteredProducts.isEmpty {
                    ContentUnavailableView(
                        "Ürün bulunamadı",
                        systemImage: "pawprint.fill",
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
                ServiceProductListView(serviceType: .pet) { product in
                    // Navigate to product detail - implement navigation logic here
                    print("Product tapped: \(product.name)")
                }
            }
            .contentMargins(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("DeliVerPet")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Pet ürünü ara…")
        .searchSuggestions {
            ForEach(petProducts.prefix(6)) { item in
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
        .animation(.snappy, value: selectedPetType)
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
        ? (colorScheme == .dark ? Color.brown.opacity(0.35) : Color.brown.opacity(0.25))
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
                .font(.system(size: 24, weight: .semibold))
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
        .shadow(color: (colorScheme == .dark ? Color.black : Color.orange).opacity(colorScheme == .dark ? 0.35 : 0.15), radius: 10, x: 0, y: 6)
    }
}

private struct PetInfoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let leftIcon: String
    let leftTitle: String
    let leftSubtitle: String
    let rightIcon: String
    let rightTitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: leftIcon).foregroundStyle(.red)
                    Text(leftTitle).font(.subheadline).bold()
                }
                Text(leftSubtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: rightIcon).foregroundStyle(.pink)
                Text(rightTitle).font(.caption).bold()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? .thinMaterial : .ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.pink.opacity(0.15))
        )
        .shadow(color: (colorScheme == .dark ? Color.black : Color.gray).opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 8, x: 0, y: 4)
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
                            ? [Color.brown.opacity(0.35), Color.orange.opacity(0.25)]
                            : [Color.brown.opacity(0.25), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.brown)
            }
            Text(title).font(.title3).bold()
            Spacer()
        }
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack { DeliVerPetView() }
}
