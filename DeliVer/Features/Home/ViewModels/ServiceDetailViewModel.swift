//
//  ServiceDetailViewModel.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 9.10.2025.
//

import Foundation

@MainActor
class ServiceDetailViewModel: ObservableObject {
    @Published var service: ServiceResponse?
    @Published var isLoading = false
    @Published var error: String?

    private let repository = ServiceRepository()

    func fetchService(id: Int64) async {
        isLoading = true
        error = nil
        
        do {
            service = try await repository.getServiceDetail(id: id)
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = "Bilinmeyen bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
