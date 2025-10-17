//
//  ProductDetailView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct ProductDetailView: View {
    let productId: Int64
    
    @StateObject private var viewModel = ProductDetailViewModel()
    @State private var showingImageViewer = false
    @State private var showingAddToCartSuccess = false
    @State private var addToCartError: String?
    
    // Sepet görünümünü göstermek için yeni state'ler
    @State private var showingCartView = false
    @State private var lastAddedCart: CartResponse?
    
    var body: some View {
        NavigationStack {
            contentView
        }
        .navigationTitle(viewModel.product?.name ?? "Ürün Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImageViewer) {
            if let imageUrl = viewModel.product?.imageUrl {
                ImageViewerSheet(imageUrl: imageUrl)
            }
        }
        .sheet(isPresented: $showingCartView) {
            // CartView now fetches its own data, so we can present it directly.
            CartView()
        }
        .onChange(of: viewModel.cartUpdateResult) { _, newValue in
            guard let result = newValue else { return }
            switch result {
            case .success(let cart):
                self.lastAddedCart = cart
                self.showingAddToCartSuccess = true
            case .failure(let error):
                self.addToCartError = error.localizedDescription
            }
            viewModel.cartUpdateResult = nil // Durumu sıfırla
        }
        .alert("Başarılı!", isPresented: $showingAddToCartSuccess) {
            Button("Sepeti Gör") {
                showingCartView = true
            }
            Button("Kapat", role: .cancel) { }
        } message: {
            Text("Ürün sepetinize başarıyla eklendi.")
        }
        .alert(
            "Hata",
            isPresented: Binding(
                get: { addToCartError != nil },
                set: { if !$0 { addToCartError = nil } }
            )
        ) {
            Button("Tamam") { addToCartError = nil }
        } message: {
            Text(addToCartError ?? "")
        }
        .task {
            await viewModel.fetchProductDetail(productId: productId)
        }
    }
}

// MARK: - Subviews
private extension ProductDetailView {
    @ViewBuilder
    var contentView: some View {
        if viewModel.isLoading {
            VStack {
                Spacer()
                ProgressView("Ürün yükleniyor...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
        } else if let error = viewModel.error {
            VStack {
                Spacer()
                ErrorView(message: error) {
                    Task {
                        await viewModel.fetchProductDetail(productId: productId)
                    }
                }
                Spacer()
            }
        } else if let product = viewModel.product {
            productDetailContent(for: product)
        } else {
            // Fallback view for unexpected states
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "questionmark.folder")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                Text("Ürün Detayı Yok")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Bu ürünün detayları şu anda mevcut değil.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
    
    func productDetailContent(for product: ProductResponse) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                productDetails(for: product)
            }
            addToCartBar
        }
    }
    
    func productDetails(for product: ProductResponse) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Product Image
            ProductImageSection(
                imageUrl: product.imageUrl,
                onImageTap: { showingImageViewer = true }
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Product Basic Info
                ProductInfoSection(product: product, viewModel: viewModel)
                
                // Product Variants
                if let variants = product.variants, !variants.isEmpty {
                    ProductVariantsSection(
                        variants: variants,
                        selectedVariant: viewModel.selectedVariant,
                        onVariantSelect: viewModel.selectVariant
                    )
                }
                
                // Product Options
                if !product.optionGroups.isEmpty {
                    ForEach(product.optionGroups) { group in
                        ProductOptionGroupSection(
                            group: group,
                            selectedOption: viewModel.selectedOptions[group.id],
                            onOptionSelect: { option in
                                viewModel.selectOption(option, for: group.id)
                            }
                        )
                    }
                }
                
                // Product Flags
                if !product.flags.isEmpty {
                    ProductFlagsSection(flags: product.flags)
                }
                
                // Description
                if let description = product.description {
                    ProductDescriptionSection(description: description)
                }
            }
            .padding(.horizontal)
        }
    }
    
    var addToCartBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Quantity Controls
                let minQ = viewModel.product.flatMap { $0.pricing.first?.minOrderQuantity } ?? 1
                let maxQ = viewModel.product.flatMap { $0.pricing.first?.maxOrderQuantity } ?? 99
                
                QuantityControlView(
                    quantity: viewModel.quantity,
                    limits: (min: minQ, max: maxQ),
                    onQuantityChange: { newValue in
                        viewModel.quantity = max(min(newValue, maxQ), minQ)
                    }
                )
                
                Spacer()
                
                // Price and Add to Cart
                let showStrike = viewModel.originalTotalPrice > viewModel.totalPrice
                let originalText = viewModel.formatPrice(viewModel.originalTotalPrice)
                let currentText = viewModel.formatPrice(viewModel.totalPrice)
                
                VStack(alignment: .trailing, spacing: 4) {
                    if showStrike {
                        Text(originalText)
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                    
                    Text(currentText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Button(action: {
                    if viewModel.canAddToCart {
                        Task {
                            await viewModel.addToCart()
                        }
                    } else {
                        addToCartError = "Lütfen gerekli seçimleri yapın ve miktarı kontrol edin."
                    }
                }) {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                        Text("Sepete Ekle")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.canAddToCart ?
                        Color.blue : Color.gray
                    )
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canAddToCart)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}


// MARK: - Product Image Section
struct ProductImageSection: View {
    let imageUrl: String?
    let onImageTap: () -> Void
    
    var body: some View {
        Button(action: onImageTap) {
            AsyncImage(url: URL(string: imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - Product Info Section
struct ProductInfoSection: View {
    let product: ProductResponse
    let viewModel: ProductDetailViewModel
    
    // Compute discount percentage locally from prices available in the view model
    private var computedDiscountPercentage: Int? {
        let original = viewModel.originalTotalPrice
        let current = viewModel.totalPrice
        guard original > 0, current < original else { return nil }
        let discount = ((original - current) / original) * 100
        let rounded = Int(discount.rounded())
        return rounded > 0 ? rounded : nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.name)
                .font(.title2)
                .fontWeight(.bold)
            
            if let shortDescription = product.shortDescription {
                Text(shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Price Info
            let showStrike = viewModel.originalTotalPrice > viewModel.totalPrice
            let originalText = viewModel.formatPrice(viewModel.originalTotalPrice)
            let currentText = viewModel.formatPrice(viewModel.totalPrice)
            let discountBadge = computedDiscountPercentage
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if showStrike {
                        Text(originalText)
                            .font(.subheadline)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                    
                    Text(currentText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let discount = discountBadge {
                    Text("-%\(discount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Product Variants Section
struct ProductVariantsSection: View {
    let variants: [ProductVariantResponse]
    let selectedVariant: ProductVariantResponse?
    let onVariantSelect: (ProductVariantResponse) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seçenekler")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(variants) { variant in
                        VariantButton(
                            variant: variant,
                            isSelected: selectedVariant?.id == variant.id,
                            onSelect: { onVariantSelect(variant) }
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

struct VariantButton: View {
    let variant: ProductVariantResponse
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: variant.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                Text(variant.name ?? variant.variantName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let additionalPrice = variant.additionalPrice, additionalPrice > 0 {
                    Text("+₺\(additionalPrice, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Option Group Section
struct ProductOptionGroupSection: View {
    let group: OptionGroupResponse
    let selectedOption: OptionValueResponse?
    let onOptionSelect: (OptionValueResponse) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(group.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if group.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if group.selectionType == "multiple" {
                    Text("Çoklu Seçim")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            if let description = group.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let options = group.options {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(options) { option in
                        OptionButton(
                            option: option,
                            isSelected: selectedOption?.id == option.id,
                            onSelect: { onOptionSelect(option) }
                        )
                    }
                }
            }
        }
    }
}

struct OptionButton: View {
    let option: OptionValueResponse
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let description = option.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let additionalPrice = option.additionalPrice, additionalPrice > 0 {
                        Text("+₺\(additionalPrice, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Other Sections
struct ProductFlagsSection: View {
    let flags: [ProductFlagResponse]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Özellikler")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(flags) { flag in
                        Text(flag.displayText ?? flag.flagType.capitalized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

struct ProductDescriptionSection: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ürün Açıklaması")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

// MARK: - Quantity Control
struct QuantityControlView: View {
    let quantity: Int
    let limits: (min: Int, max: Int)
    let onQuantityChange: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                onQuantityChange(quantity - 1)
            }) {
                Image(systemName: "minus")
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(quantity > limits.min ? Color.blue : Color.gray)
                    .clipShape(Circle())
            }
            .disabled(quantity <= limits.min)
            
            Text("\(quantity)")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(minWidth: 30)
            
            Button(action: {
                onQuantityChange(quantity + 1)
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(quantity < limits.max ? Color.blue : Color.gray)
                    .clipShape(Circle())
            }
            .disabled(quantity >= limits.max)
        }
    }
}

// MARK: - Image Viewer Sheet
struct ImageViewerSheet: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .navigationTitle("Ürün Görseli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProductDetailView(productId: 1)
}
