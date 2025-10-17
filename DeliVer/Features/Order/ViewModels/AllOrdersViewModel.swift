//
//  AllOrdersViewModel.swift
//  DeliVer
//
//  Created by [Your Name] on [Date].
//

import Foundation

@MainActor
class AllOrdersViewModel: ObservableObject {
    @Published var orders: [OrderResponse] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var viewState: ViewState = .loading
    
    private var currentPage = 0
    private var canLoadMorePages = true
    private let orderRepository = OrderRepository()
    
    enum ViewState {
        case loading
        case content
        case empty
        case error(String)
    }

    func fetchInitialOrders() async {
        // Zaten yükleniyorsa veya tüm sayfalar yüklendiyse tekrar yükleme yapma
        guard !isLoading else { return }
        
        // Yenileme işlemi için sıfırla
        orders = []
        currentPage = 0
        canLoadMorePages = true
        viewState = .loading
        
        await loadMoreOrders()
    }
    
    func loadMoreOrders() async {
        guard !isLoading, canLoadMorePages else { return }
        
        isLoading = true
        
        do {
            let paginatedResponse = try await orderRepository.getUserOrders(page: currentPage)
            orders.append(contentsOf: paginatedResponse.content)
            
            canLoadMorePages = !paginatedResponse.last
            currentPage += 1
            
            viewState = orders.isEmpty ? .empty : .content
            
        } catch let apiError as APIError {
            viewState = .error(apiError.localizedDescription)
        } catch {
            viewState = .error(error.localizedDescription)
        }
        
        isLoading = false
    }
}
