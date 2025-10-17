//
//  ProductListView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct ProductListView: View {
    let categoryId: Int64
    let categoryName: String
    
    @StateObject private var viewModel = ProductListViewModel()
    @State private var showingFilters = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                HStack {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Ürün ara...", text: $viewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Filter Button
                    Button(action: { showingFilters = true }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filtre")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                // Alt boşluğu artır: ürünler arama çubuğuna çok yakın olmasın
                .padding(.bottom, 12)
                
                // Filter Summary
                if viewModel.showOnlyDiscounted || viewModel.sortOrder != .none {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if viewModel.showOnlyDiscounted {
                                FilterChip(title: "İndirimli (\(viewModel.discountedProductsCount))") {
                                    viewModel.showOnlyDiscounted = false
                                }
                            }
                            
                            if viewModel.sortOrder != .none {
                                FilterChip(title: viewModel.sortOrder.rawValue) {
                                    viewModel.sortOrder = .none
                                }
                            }
                            
                            Button("Tümünü Temizle") {
                                viewModel.resetFilters()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Ürünler yükleniyor...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                } else if let error = viewModel.error {
                    VStack {
                        Spacer()
                        ErrorView(message: error) {
                            Task {
                                await viewModel.refreshProducts()
                            }
                        }
                        Spacer()
                    }
                } else if viewModel.filteredAndSortedProducts.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "cube.box",
                            title: "Ürün bulunamadı",
                            message: viewModel.searchText.isEmpty ? 
                                "Bu kategoride ürün bulunmuyor." : 
                                "Arama kriterlerinize uygun ürün bulunamadı."
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.filteredAndSortedProducts) { product in
                                NavigationLink(
                                    destination: ProductDetailView(productId: product.id)
                                ) {
                                    ProductCardView(product: product, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await viewModel.refreshProducts()
                    }
                }
            }
            .navigationTitle(categoryName)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFilters) {
                ProductFiltersView(viewModel: viewModel)
            }
            .task {
                await viewModel.fetchProducts(for: categoryId)
            }
        }
    }
}

struct ProductCardView: View {
    let product: ProductResponse
    let viewModel: ProductListViewModel
    
    var body: some View {
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
                
                if let shortDescription = product.shortDescription {
                    Text(shortDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Price Section
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if viewModel.hasDiscount(for: product) {
                            if let originalPrice = viewModel.getOriginalPrice(for: product) {
                                Text(formatPrice(originalPrice))
                                    .font(.caption)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(formatPrice(viewModel.getCurrentPrice(for: product)))
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "₺\(price)"
    }
}

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

struct ProductFiltersView: View {
    @ObservedObject var viewModel: ProductListViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Sıralama") {
                    Picker("Sıralama", selection: $viewModel.sortOrder) {
                        ForEach(ProductListViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Filtreler") {
                    Toggle("Sadece İndirimli Ürünler", isOn: $viewModel.showOnlyDiscounted)
                }
                
                Section("Fiyat Aralığı") {
                    HStack {
                        Text("₺\(Int(viewModel.priceRange.lowerBound))")
                        Spacer()
                        Text("₺\(Int(viewModel.priceRange.upperBound))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Filtreleri Sıfırla") {
                        viewModel.resetFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProductListView(categoryId: 1, categoryName: "Hamburger")
}
