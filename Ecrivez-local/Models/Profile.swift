//
//  Profile.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 1/16/25.
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: String
//    let created_at: String?
    var username: String?
    var email: String?
    var display_name: String?
    var profile_photo_url: String? // New field
    
    init(id: String, username: String? = nil, email: String? = nil, display_name: String? = nil, profile_photo_url: String? = nil) {
        self.id = id
//        self.created_at = nil
        self.username = username
        self.email = email
        self.display_name = display_name
        self.profile_photo_url = profile_photo_url
    }
}
