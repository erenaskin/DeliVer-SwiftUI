//
//  DeliVerWaterView.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import SwiftUI

struct DeliVerWaterView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "Tümü"
    @State private var selectedSize = "Hepsi"
    @State private var subscriptionMode = false
    
    let categories = ["Tümü", "İçme Suyu", "Doğal Su", "Maden Suyu", "Arıtma Cihazı", "Filtre"]
    let sizes = ["Hepsi", "0.5L", "1L", "5L", "19L", "Galon"]
    
    let waterProducts: [Product] = [
        Product(name: "Damacana Su 19L", description: "Premium içme suyu", price: 12.00, imageName: "drop.fill"),
        Product(name: "Doğal Kaynak Suyu 1L", description: "6'lı paket doğal su", price: 18.00, imageName: "drop.circle.fill"),
        Product(name: "Maden Suyu 500ml", description: "Gazlı maden suyu 24'lü", price: 45.00, imageName: "bubbles.and.sparkles.fill"),
        Product(name: "Su Arıtma Cihazı", description: "5 kademeli arıtma sistemi", price: 1250.00, imageName: "shower.fill"),
        Product(name: "Filtre Kartuşu", description: "Değiştirilebilir su filtresi", price: 85.00, imageName: "circle.hexagongrid.fill"),
        Product(name: "Su Sebili", description: "Sıcak & soğuk su makinesi", price: 899.00, imageName: "waterbottle.fill"),
        Product(name: "Alkalin Su 1.5L", description: "pH dengeli alkalin su", price: 25.00, imageName: "drop.triangle.fill"),
        Product(name: "Bebek Suyu 1L", description: "Düşük mineral bebek suyu", price: 15.00, imageName: "baby.bottle.fill")
    ]
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return waterProducts
        } else {
            return waterProducts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Subscription Toggle
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscriptionMode ? "ABONELİK MODU" : "Tek Seferlik Sipariş")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(subscriptionMode ? .white : .primary)
                        
                        Text(subscriptionMode ? "Düzenli teslimat %20 indirim" : "Normal fiyatlarla sipariş")
                            .font(.subheadline)
                            .foregroundColor(subscriptionMode ? .white.opacity(0.9) : .secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("Abonelik", isOn: $subscriptionMode)
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                }
                .padding()
                .background {
                    if subscriptionMode {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.cyan]),
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
                
                TextField("Su ürünü ara...", text: $searchText)
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
            
            // Size Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sizes, id: \.self) { size in
                        Button(action: { selectedSize = size }) {
                            Text(size)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedSize == size ? 
                                    Color.cyan : Color(.systemGray6)
                                )
                                .foregroundColor(
                                    selectedSize == size ? 
                                    .white : .primary
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
            
            // Water Quality Banner
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Su Kalite Güvencesi!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Laboratuvar testli hijyenik su")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("GÜVENLİ")
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
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
            
            // Water Type Categories
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Su Türleri")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        WaterCategoryCard(title: "İçme Suyu", icon: "drop.fill", color: .blue)
                        WaterCategoryCard(title: "Doğal Su", icon: "drop.circle.fill", color: .green)
                        WaterCategoryCard(title: "Maden Suyu", icon: "bubbles.and.sparkles.fill", color: .cyan)
                        WaterCategoryCard(title: "Arıtma", icon: "shower.fill", color: .purple)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 16)
            
            // Delivery Schedule
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            
                            Text("Teslimat Planı")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Günlük saat 09:00-18:00 arası teslimat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                            
                            Text("Bildirim")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Teslimat öncesi SMS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
            
            // Products Grid
            ScrollView {
                if filteredProducts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "drop.fill")
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
                ServiceProductListView(serviceType: .water) { product in
                    // Navigate to product detail - implement navigation logic here
                    print("Product tapped: \(product.name)")
                }
            }
        }
        .navigationTitle("DeliVerWater")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct WaterCategoryCard: View {
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
    NavigationStack { DeliVerWaterView() }
}
