//
//  CategoryListViewModel.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

@MainActor
class CategoryListViewModel: ObservableObject {
    @Published var categories: [CategoryResponse] = []
    @Published var subcategories: [Int64: [CategoryResponse]] = [:]
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""
    
    private let repository = CategoryRepository()
    private var currentServiceId: Int64?
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Belirli bir servise ait kategorileri yükle
    func fetchCategories(for serviceId: Int64) async {
        currentServiceId = serviceId
        isLoading = true
        error = nil
        
        do {
            categories = try await repository.getMainCategories(for: serviceId)
            
            // Her ana kategori için alt kategorileri yükle
            await loadSubcategoriesForAllCategories()
            
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = "Bilinmeyen bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Belirli bir kategorinin alt kategorilerini yükle
    func loadSubcategories(for categoryId: Int64) async {
        do {
            let subs = try await repository.getSubcategories(for: categoryId)
            subcategories[categoryId] = subs
        } catch {
            print("Alt kategoriler yüklenemedi: \(error.localizedDescription)")
        }
    }
    
    /// Kategorileri yenile
    func refreshCategories() async {
        guard let serviceId = currentServiceId else { return }
        await fetchCategories(for: serviceId)
    }
    
    // MARK: - Computed Properties
    
    /// Arama yapılmış kategoriler
    var filteredCategories: [CategoryResponse] {
        if searchText.isEmpty {
            return activeCategories
        }
        return activeCategories.filter { category in
            category.name.localizedCaseInsensitiveContains(searchText) ||
            category.description?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    /// Aktif kategoriler
    var activeCategories: [CategoryResponse] {
        categories.filter { $0.isActive }
    }
    
    /// Belirli bir kategorinin alt kategorilerini getir
    func getSubcategories(for categoryId: Int64) -> [CategoryResponse] {
        return subcategories[categoryId]?.filter { $0.isActive } ?? []
    }
    
    /// Kategorinin alt kategorisi var mı kontrol et
    func hasSubcategories(_ categoryId: Int64) -> Bool {
        return !getSubcategories(for: categoryId).isEmpty
    }
    
    // MARK: - Private Methods
    
    private func loadSubcategoriesForAllCategories() async {
        await withTaskGroup(of: Void.self) { group in
            for category in categories {
                group.addTask {
                    await self.loadSubcategories(for: category.id)
                }
            }
        }
    }
}