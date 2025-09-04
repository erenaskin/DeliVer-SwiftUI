//
//  RegisterRequest.swift
//  DeliVer
//
//  Created by Eren AŞKIN on 31.08.2025.
//

import Foundation

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}
