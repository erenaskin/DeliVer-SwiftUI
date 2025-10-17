//
//  SErvice.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 10.09.2025.
//

import Foundation

struct Service: Identifiable, Codable {
    let id: Int64
    let name: String
    let description: String
    let price: Double

    enum CodingKeys: String, CodingKey {
        case id, name, description, price
    }

    init(id: Int64, name: String, description: String, price: Double) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id ve name zorunlu
        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        // description eksik/null ise boş stringe düş
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""

        // price farklı formatlarda gelebilir:
        // - number (Double/Int)
        // - string ("25.00")
        // - eksik/null -> 0.0
        if let number = try? container.decode(Double.self, forKey: .price) {
            self.price = number
        } else if let intNumber = try? container.decode(Int.self, forKey: .price) {
            self.price = Double(intNumber)
        } else if let stringNumber = try? container.decode(String.self, forKey: .price) {
            // Virgül/dot farklılıklarına karşı normalize et
            let normalized = stringNumber.replacingOccurrences(of: ",", with: ".")
            self.price = Double(normalized) ?? 0.0
        } else {
            self.price = 0.0
        }
    }
}
