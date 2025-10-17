//
//  CategoryRepository.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

class CategoryRepository {
    private let apiService = APIService.shared
    
    /// Belirli bir servise ait tüm kategorileri getir
    func getCategories(for serviceId: Int64) async throws -> [CategoryResponse] {
        try await apiService.fetchCategories(for: serviceId)
    }
    
    /// Belirli bir servise ait ana kategorileri getir (parent_id nil olanlar)
    func getMainCategories(for serviceId: Int64) async throws -> [CategoryResponse] {
        try await apiService.fetchMainCategories(for: serviceId)
    }
    
    /// Belirli bir kategorinin alt kategorilerini getir
    func getSubcategories(for categoryId: Int64) async throws -> [CategoryResponse] {
        try await apiService.fetchSubcategories(for: categoryId)
    }
    
    /// Belirli bir kategorinin tüm alt kategorilerini recursive olarak getir
    func getAllSubcategories(for categoryId: Int64) async throws -> [CategoryResponse] {
        try await apiService.fetchAllSubcategories(for: categoryId)
    }
}