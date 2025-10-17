//
//  DeliVerTechView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct DeliVerTechView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var orderViewModel = OrderViewModel()
    
    @State private var searchText = ""
    @State private var selectedServiceType = "Hepsi"
    @State private var sortOption: SortOption = .popularity
    @State private var showingOrderStatus = false
    
    private let serviceTypes = ["Hepsi", "Tamir", "Kurulum", "Bakım", "Veri Kurtarma"]
    
    private let services: [Product] = [
        Product(name: "iPhone Ekran Tamiri", description: "Orijinal ekran garantili", price: 899.0, imageName: "iphone"),
        Product(name: "Laptop RAM Yükseltme", description: "8GB→16GB RAM yükseltme", price: 450.0, imageName: "memorychip.fill"),
        Product(name: "Android Yazılım Tamiri", description: "Sistem onarımı ve güncelleme", price: 299.0, imageName: "gear.circle.fill"),
        Product(name: "MacBook Batarya Değişimi", description: "Apple orijinal batarya", price: 750.0, imageName: "battery.100.bolt"),
        Product(name: "PC Temizlik & Bakım", description: "Kapsamlı sistem temizliği", price: 199.0, imageName: "wind"),
        Product(name: "Veri Kurtarma Servisi", description: "Güvenli veri kurtarma", price: 599.0, imageName: "externaldrive.fill"),
        Product(name: "Gaming PC Kurulumu", description: "Özel oyun bilgisayarı montajı", price: 399.0, imageName: "gamecontroller.fill"),
        Product(name: "Akıllı Saat Tamiri", description: "Apple Watch & Samsung", price: 349.0, imageName: "applewatch")
    ]
    
    private var filteredServices: [Product] {
        var list = services
        if selectedServiceType != "Hepsi" {
            let key = selectedServiceType.lowercased()
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
                    title: "Acil Teknik Servis!",
                    subtitle: "24/7 acil müdahale hizmeti",
                    gradient: Gradient(colors: [Color.purple, Color.pink]),
                    leadingIcon: "phone.fill"
                )
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(serviceTypes, id: \.self) { type in
                            CategoryChip(
                                title: type,
                                isSelected: selectedServiceType == type,
                                baseColor: .purple
                            ) {
                                withAnimation(.snappy) { selectedServiceType = type }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                WarrantyCard()
                    .padding(.horizontal)
                
                SectionHeader(title: "Teknik Servisler", systemImage: "wrench.and.screwdriver")
                    .padding(.horizontal)
                
                if filteredServices.isEmpty {
                    ContentUnavailableView(
                        "Servis bulunamadı",
                        systemImage: "wrench.and.screwdriver",
                        description: Text("Arama veya filtreleri düzenlemeyi deneyin")
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .padding(.horizontal)
                } else {
                    LazyVGrid(columns: grid, spacing: 16) {
                        ForEach(filteredServices) { service in
                            ProductCard(product: service)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                                        .shadow(color: (colorScheme == .dark ? Color.black : Color.gray).opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 6, x: 0, y: 3)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale))
                }
                
                // API Products Section
                ServiceProductListView(serviceType: .tech) { product in
                    // Navigate to product detail - implement navigation logic here
                    print("Product tapped: \(product.name)")
                }
            }
            .contentMargins(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("DeliVerTech")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Servis ara…")
        .searchSuggestions {
            ForEach(services.prefix(6)) { item in
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
        .animation(.snappy, value: selectedServiceType)
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

// MARK: - Nested Helpers (scoped to DeliVerTechView)

extension DeliVerTechView {
    enum SortOption: CaseIterable {
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
    
    struct CategoryChip: View {
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
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [baseColor, baseColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
            ? (colorScheme == .dark ? Color.purple.opacity(0.35) : Color.purple.opacity(0.25))
            : .clear
        }
    }
    
    struct PromoCard: View {
        @Environment(\.colorScheme) private var colorScheme
        
        let title: String
        let subtitle: String
        let gradient: Gradient
        let leadingIcon: String
        
        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline).bold()
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: leadingIcon)
                    .font(.system(size: 26, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .white.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.05)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: (colorScheme == .dark ? Color.black : Color.purple).opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 10, x: 0, y: 6)
        }
    }
    
    struct WarrantyCard: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, .white)
                    Text("Tüm tamirlerde 6 ay garanti")
                        .font(.subheadline).bold()
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("4.8★")
                        .font(.subheadline).bold()
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? .thinMaterial : .ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.green.opacity(0.25), Color.purple.opacity(0.15)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: (colorScheme == .dark ? Color.black : Color.gray).opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 8, x: 0, y: 4)
        }
    }
    
    struct SectionHeader: View {
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
                                ? [Color.purple.opacity(0.35), Color.pink.opacity(0.25)]
                                : [Color.purple.opacity(0.25), Color.pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 30)
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.purple)
                }
                Text(title)
                    .font(.title3).bold()
                Spacer()
            }
            .padding(.top, 4)
        }
    }
}

#Preview {
    NavigationStack { DeliVerTechView() }
}
