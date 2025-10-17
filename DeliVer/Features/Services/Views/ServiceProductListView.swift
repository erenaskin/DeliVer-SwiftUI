//
//  ServiceProductListView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 7.10.2025.
//

import SwiftUI

struct ServiceProductListView: View {
    let serviceType: ServiceType
    let onProductTap: ((ProductResponse) -> Void)?
    
    @StateObject private var viewModel = ServiceProductListViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(serviceType: ServiceType, onProductTap: ((ProductResponse) -> Void)? = nil) {
        self.serviceType = serviceType
        self.onProductTap = onProductTap
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Section Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                ? [Color.blue.opacity(0.35), Color.purple.opacity(0.25)]
                                : [Color.blue.opacity(0.25), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 30)
                    Image(systemName: serviceType.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                Text("Ürünler")
                    .font(.title3).bold()
                Spacer()
                
                // Search clear button
                if viewModel.isSearching {
                    Button("Temizle") {
                        viewModel.clearSearch()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // Content
            if viewModel.isLoading {
                LoadingView()
                    .frame(height: 200)
            } else if let error = viewModel.error {
                ErrorStateView(
                    message: error,
                    onRetry: {
                        Task {
                            await viewModel.refreshProducts()
                        }
                    }
                )
                .frame(height: 200)
            } else if viewModel.isEmpty {
                EmptyStateView(
                    icon: "cube.box",
                    title: viewModel.isSearching ? "Arama sonucu bulunamadı" : "Ürün bulunamadı",
                    message: viewModel.isSearching ?
                        "Arama kriterlerinize uygun ürün bulunamadı." :
                        "Bu serviste henüz ürün bulunmuyor."
                )
                .frame(height: 200)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.products) { product in
                        ServiceProductCard(product: product, viewModel: viewModel) {
                            onProductTap?(product)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .task {
            await viewModel.fetchProducts(for: serviceType)
        }
        .refreshable {
            await viewModel.refreshProducts()
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "\(serviceType.displayName) ürünlerinde ara..."
        )
    }
}

// MARK: - ServiceProductCard
struct ServiceProductCard: View {
    let product: ProductResponse
    let viewModel: ServiceProductListViewModel
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Product Image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let shortDescription = product.shortDescription {
                        Text(shortDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Price Section
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if viewModel.hasDiscount(for: product) {
                                Text(viewModel.formatPrice(viewModel.getOriginalPrice(for: product)))
                                    .font(.caption)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(viewModel.formatPrice(viewModel.getCurrentPrice(for: product)))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Discount Badge
                        if let discount = viewModel.getDiscountPercentage(for: product) {
                            Text("-%\(Int(discount))")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05),
                        lineWidth: 1
                    )
            )
            .overlay(
                // Product Flags
                VStack {
                    HStack {
                        if !product.flags.isEmpty {
                            ForEach(product.flags.prefix(2)) { flag in
                                Text(flag.displayText ?? flag.flagType.capitalized)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8),
                alignment: .topLeading
            )
            .shadow(
                color: (colorScheme == .dark ? Color.black : Color.gray).opacity(colorScheme == .dark ? 0.4 : 0.15),
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

// MARK: - Support Views
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("Ürünler yükleniyor...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Bir hata oluştu")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Tekrar Dene") {
                onRetry()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ServiceProductListView(serviceType: .tech) { product in
                print("Product tapped: \(product.name)")
            }
        }
        .navigationTitle("DeliVerTech")
    }
}
