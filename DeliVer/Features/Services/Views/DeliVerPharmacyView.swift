//
//  DeliVerPharmacyView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct DeliVerPharmacyView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "Tümü"
    @State private var emergencyMode = false
    
    let categories = ["Tümü", "Reçeteli İlaç", "Reçetesiz İlaç", "Vitamin", "Bebek & Anne", "Kozmetik", "Medikal"]
    
    let pharmacyProducts: [Product] = [
        Product(name: "Parol 500mg", description: "Ağrı kesici & ateş düşürücü", price: 12.50, imageName: "pills.fill"),
        Product(name: "Vitamin D3", description: "1000 IU 30 tablet", price: 45.00, imageName: "sun.max.fill"),
        Product(name: "Aspirin Protect", description: "Kalp koruyucu 100mg", price: 28.50, imageName: "heart.fill"),
        Product(name: "Bebek Bezi", description: "4 numara 32'li paket", price: 89.00, imageName: "baby.bottle.fill"),
        Product(name: "El Antiseptiği", description: "500ml hijyen jeli", price: 35.00, imageName: "hand.raised.fill"),
        Product(name: "Termometre", description: "Dijital ateş ölçer", price: 75.00, imageName: "thermometer"),
        Product(name: "Omega-3", description: "Balık yağı 1000mg", price: 125.00, imageName: "drop.fill"),
        Product(name: "Maske", description: "50'li cerrahi maske", price: 25.00, imageName: "face.dashed.fill")
    ]
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return pharmacyProducts
        } else {
            return pharmacyProducts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Emergency Toggle
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(emergencyMode ? "ACİL ECZANE MODU" : "Normal Mod")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(emergencyMode ? .white : .primary)
                        
                        Text(emergencyMode ? "24 saat içinde teslim" : "Standart teslimat")
                            .font(.subheadline)
                            .foregroundColor(emergencyMode ? .white.opacity(0.9) : .secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("Acil Mod", isOn: $emergencyMode)
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                }
                .padding()
                .background {
                    if emergencyMode {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(.systemGray6)
                    }
                }
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("İlaç veya ürün ara...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
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
            .padding(.bottom, 12)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategory == category ? 
                                    Color.red : Color(.systemGray6)
                                )
                                .foregroundColor(
                                    selectedCategory == category ? 
                                    .white : .primary
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
            
            // Prescription Upload
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reçeteli İlaç")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Reçetenizi yükleyin, size hazırlayalım")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("YÜKLE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
            
            // Quick Access Categories
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Hızlı Erişim")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        PharmacyCategoryCard(title: "Ağrı Kesici", icon: "pills.fill", color: .red)
                        PharmacyCategoryCard(title: "Vitamin", icon: "sun.max.fill", color: .orange)
                        PharmacyCategoryCard(title: "Bebek", icon: "baby.bottle.fill", color: .pink)
                        PharmacyCategoryCard(title: "Kozmetik", icon: "sparkles", color: .purple)
                        PharmacyCategoryCard(title: "Medikal", icon: "cross.fill", color: .blue)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 16)
            
            // Pharmacist Consultation
            HStack {
                Image(systemName: "person.fill.checkmark")
                    .foregroundColor(.green)
                
                Text("Uzman eczacıdan ücretsiz danışmanlık")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("DANIŞ") {
                    // Consultation action
                }
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Products Grid
            ScrollView {
                if filteredProducts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cross.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Ürün bulunamadı")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Arama kriterlerinizi değiştirmeyi deneyin")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredProducts) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                
                // API Products Section
                ServiceProductListView(serviceType: .pharmacy) { product in
                    // Navigate to product detail - implement navigation logic here
                    print("Product tapped: \(product.name)")
                }
            }
        }
        .navigationTitle("DeliVerPharmacy")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PharmacyCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(25)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
    }
}
#Preview {
    DeliVerPharmacyView()
}
