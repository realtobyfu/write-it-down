//
//  CurrentUserSession.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/5/25.
//

import Foundation

/// Minimal data we need to restore a Supabase session
struct CurrentUserSession: Codable, Equatable, Identifiable {
    let id: UUID = UUID()
    
    let accessToken: String
    let refreshToken: String
    // If you want to store the user’s ID or other details, add them here.
    
    init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
