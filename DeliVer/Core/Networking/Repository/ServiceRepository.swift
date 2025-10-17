//
//  ServiceRepository.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 10.09.2025.
//

import Foundation

class ServiceRepository {
    private let apiService = APIService.shared
    
    func getServices() async throws -> [ServiceResponse] {
        try await apiService.fetchServices()
    }

    func getServiceDetail(id: Int64) async throws -> ServiceResponse? {
        try await apiService.fetchServiceDetail(serviceId: id)
    }
}
