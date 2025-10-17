//
//  ServiceListViewModel.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 10.09.2025.
//

import Foundation

@MainActor
class ServiceListViewModel: ObservableObject {
    @Published var services: [ServiceResponse] = []
    @Published var isLoading = false
    @Published var error: String?

    private let repository = ServiceRepository()

    init() {
        // ViewModel oluşturulduğunda otomatik yükle
        Task {
            await fetchServices()
        }
    }

    func fetchServices() async {
        isLoading = true
        error = nil
        
        do {
            services = try await repository.getServices()
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = "Bilinmeyen bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshServices() async {
        await fetchServices()
    }
    
    // Aktif servisleri filtrele
    var activeServices: [ServiceResponse] {
        services.filter { $0.isActive }
    }
    
    // Servis arama fonksiyonu
    func searchServices(query: String) -> [ServiceResponse] {
        if query.isEmpty {
            return activeServices
        }
        return activeServices.filter { service in
            service.name.localizedCaseInsensitiveContains(query) ||
            service.description?.localizedCaseInsensitiveContains(query) == true
        }
    }
}
