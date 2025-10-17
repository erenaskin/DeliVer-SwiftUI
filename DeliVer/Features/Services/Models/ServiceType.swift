//
//  ServiceType.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 23.09.2025.
//

import Foundation

enum ServiceType: Int, CaseIterable {
    case tech = 1       // DeliVerTech
    case food = 2       // DeliVerFood  
    case market = 3     // DeliVerMarket
    case pet = 4        // DeliVerPet
    case water = 5      // DeliVerWater
    case pharmacy = 6   // DeliVerPharmacy
    
    var displayName: String {
        switch self {
        case .tech: return "DeliVerTech"
        case .food: return "DeliVerFood"
        case .market: return "DeliVerMarket"
        case .pet: return "DeliVerPet"
        case .water: return "DeliVerWater"
        case .pharmacy: return "DeliVerPharmacy"
        }
    }
    
    var icon: String {
        switch self {
        case .tech: return "laptopcomputer"
        case .food: return "fork.knife"
        case .market: return "cart"
        case .pet: return "pawprint"
        case .water: return "drop"
        case .pharmacy: return "cross.vial"
        }
    }
}
