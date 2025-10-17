//
//  DeliVerFoodView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct DeliVerFoodView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    // Servis bazlı tekrar kullanılabilir ekran
    let serviceId: Int64
    let title: String
    
    @StateObject private var viewModel = ProductListViewModel()
    @State private var categories: [CategoryResponse] = []
    @State private var subcategoriesMap: [Int64: [CategoryResponse]] = [:]
    @State private var selectedCategoryId: Int64? = nil // nil = Tümü
    @State private var isLoadingCategories = false
    @State private var categoryError: String?
    

    private let productRepository = ProductRepository()
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var allButtonCircleGradient: LinearGradient {
        if selectedCategoryId == nil {
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color(.systemGray5), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            categorySection
            promotionalBanner
            productsSection
            apiProductsSection
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: selectedCategoryId) { _, _ in
            Task { await loadProducts() }
        }
        .task {
            await initialLoad()
        }
    }
    
    // MARK: - Data Loading
    private func initialLoad() async {
        await loadCategories()
        await loadProducts()
    }
    
    private func loadCategories() async {
        isLoadingCategories = true
        categoryError = nil
        do {
            // Root (parentId == nil) + aktif kategoriler
            let allCategories = try await APIService.shared.fetchCategories(for: serviceId)
            categories = allCategories.filter { $0.parentId == nil && $0.isActive }
            
            // Alt kategorileri yükle
            subcategoriesMap.removeAll()
            for category in categories {
                do {
                    let subcats = try await APIService.shared.fetchSubcategories(for: category.id)
                    subcategoriesMap[category.id] = subcats.filter { $0.isActive }
                } catch {
                    print("Alt kategoriler yüklenemedi (\(category.name)): \(error)")
                    subcategoriesMap[category.id] = []
                }
            }
        } catch let apiError as APIError {
            categoryError = apiError.localizedDescription
        } catch {
            categoryError = error.localizedDescription
        }
        isLoadingCategories = false
    }
    
    private func loadProducts() async {
        viewModel.error = nil
        if let categoryId = selectedCategoryId {
            await viewModel.fetchProducts(for: categoryId)
        } else {
            // "Tümü": servise ait tüm ürünleri getir
            viewModel.isLoading = true
            do {
                let items = try await productRepository.getProducts(forService: serviceId)
                viewModel.products = items
            } catch let apiError as APIError {
                viewModel.error = apiError.localizedDescription
            } catch {
                viewModel.error = error.localizedDescription
            }
            viewModel.isLoading = false
        }
    }
}

// MARK: - View Components
private extension DeliVerFoodView {
    
    var searchBar: some View {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var categorySection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // "Tümü" seçeneği
                Button(action: {
                    selectedCategoryId = nil
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(allButtonCircleGradient)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(selectedCategoryId == nil ? .white : .primary)
                        }
                        
                        Text("Tümü")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedCategoryId == nil {
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
                                selectedCategoryId == nil ?
                                Color.orange.opacity(0.1) :
                                Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                
                // Ana kategoriler ve alt kategorileri
                ForEach(categories) { category in
                    ExpandableCategoryView(
                        category: category,
                        subcategories: subcategoriesMap[category.id] ?? [],
                        selectedCategoryId: $selectedCategoryId,
                        onCategorySelect: { categoryId in
                            selectedCategoryId = categoryId
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 200)
        .padding(.vertical, 12)
    }
    
    var promotionalBanner: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ücretsiz Teslimat!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("50₺ ve üzeri siparişlerde")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "scooter")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange, Color.red]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    var productsSection: some View {
        if isLoadingCategories || viewModel.isLoading {
            loadingView
        } else if let error = categoryError ?? viewModel.error {
            errorView(message: error)
        } else {
            productsScrollView
        }
    }
    
    private var productsScrollView: some View {
        ScrollView {
            let products = viewModel.filteredAndSortedProducts
            if products.isEmpty {
                emptyProductsView
            } else {
                productsGridView(for: products)
            }
        }
    }
    
    var apiProductsSection: some View {
        ServiceProductListView(serviceType: .food) { product in
            // Navigate to product detail - implement navigation logic here
            print("API Product tapped: \(product.name)")
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Yükleniyor...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .foregroundColor(.secondary)
            Button("Tekrar Dene") {
                Task { await initialLoad() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 50)
    }
    
    private var emptyProductsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Ürün bulunamadı")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Arama kriterlerinizi veya kategori seçimini değiştirin")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
    
    private func productsGridView(for products: [ProductResponse]) -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(products) { product in
                NavigationLink {
                    // NOTE: The definition for ProductDetailView was not provided.
                    // Please replace this placeholder with your actual detail view.
                    Text("Product Detail for ID: \(product.id)")
                } label: {
                    ProductResponseCard(
                        product: product,
                        currentPrice: viewModel.getCurrentPrice(for: product),
                        originalPrice: viewModel.getOriginalPrice(for: product) ?? 0.0,
                        hasDiscount: viewModel.hasDiscount(for: product)
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

#Preview {
    NavigationStack {
        DeliVerFoodView(serviceId: 1, title: "Yemek")
    }
}
