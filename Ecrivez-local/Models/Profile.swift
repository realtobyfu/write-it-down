//
//  Profile.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 1/16/25.
//

import Foundation

/// A Swift model that represents a row in the "profiles" table
/// which has columns: id, created_at, username, email, display_name.
struct Profile: Codable, Identifiable {
    // We’ll store `id` as a String, because `session.user.id` is typically a String.
    // The Supabase Swift library will attempt to convert it to/from UUID behind the scenes.
    let id: String
    
    // This can be optional since the row might not have a value yet
    let created_at: String?
    
    var username: String?
    var email: String?
    var display_name: String?
    
    // You can add an init if you want easy creation
    init(id: String, username: String? = nil, email: String? = nil, display_name: String? = nil) {
        self.id = id
        self.created_at = nil
        self.username = username
        self.email = email
        self.display_name = display_name
    }
}
