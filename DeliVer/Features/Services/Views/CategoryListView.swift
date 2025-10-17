//
//  CategoryListView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct CategoryListView: View {
    let serviceId: Int64
    let serviceName: String
    
    @StateObject private var viewModel = CategoryListViewModel()
    @State private var expandedCategories: Set<Int64> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Kategori ara...", text: $viewModel.searchText)
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
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Kategoriler yükleniyor...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                } else if let error = viewModel.error {
                    VStack {
                        Spacer()
                        ErrorView(message: error) {
                            Task {
                                await viewModel.refreshCategories()
                            }
                        }
                        Spacer()
                    }
                } else if viewModel.filteredCategories.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "folder",
                            title: "Kategori bulunamadı",
                            message: "Bu servise ait kategori bulunmuyor."
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredCategories) { category in
                                categoryCell(for: category)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await viewModel.refreshCategories()
                    }
                }
            }
            .navigationTitle(serviceName)
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.fetchCategories(for: serviceId)
            }
        }
    }

    @ViewBuilder
    private func categoryCell(for category: CategoryResponse) -> some View {
        let hasSubcategories = viewModel.hasSubcategories(category.id)
        let isExpanded = expandedCategories.contains(category.id)
        
        VStack(spacing: 0) {
            if hasSubcategories {
                // Genişletilebilir Kategori Başlığı
                CategoryHeaderView(category: category, isExpanded: isExpanded, isExpandable: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            if isExpanded {
                                expandedCategories.remove(category.id)
                            } else {
                                expandedCategories.insert(category.id)
                            }
                        }
                    }
                
                // Genişletilmiş İçerik (Alt Kategoriler vb.)
                if isExpanded {
                    ExpandedCategoryContentView(
                        category: category,
                        subcategories: viewModel.getSubcategories(for: category.id)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    .padding(.top, 8)
                }
            } else {
                // Doğrudan Ürün Listesine Giden Kategori
                NavigationLink(destination: ProductListView(categoryId: category.id, categoryName: category.name)) {
                    CategoryHeaderView(category: category, isExpanded: false, isExpandable: false)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Helper Views

// Ana kategori satırını temsil eden view
struct CategoryHeaderView: View {
    let category: CategoryResponse
    let isExpanded: Bool
    let isExpandable: Bool

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: category.iconUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
            }
            .frame(width: 40, height: 40)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let description = category.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if isExpandable {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
                    .font(.callout)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.callout)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Genişletildiğinde gösterilen içerik
struct ExpandedCategoryContentView: View {
    let category: CategoryResponse
    let subcategories: [CategoryResponse]

    var body: some View {
        VStack(spacing: 8) {
            // "Tüm Ürünleri Gör" linki
            NavigationLink(destination: ProductListView(categoryId: category.id, categoryName: category.name)) {
                HStack {
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    Text("Tüm \(category.name) Ürünleri")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            // Alt Kategori linkleri
            ForEach(subcategories) { subcategory in
                NavigationLink(destination: ProductListView(categoryId: subcategory.id, categoryName: subcategory.name)) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        
                        Text(subcategory.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20) // Alt kategorileri biraz içeriden başlat
    }
}

// Mevcut Hata ve Önizleme View'ları
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Hata")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Tekrar Dene", action: onRetry)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    CategoryListView(serviceId: 1, serviceName: "DeliVerFood")
}
