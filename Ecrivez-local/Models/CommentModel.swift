//
//  CommentModel.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/5/25.
//

import Foundation

struct CommentModel: Codable, Identifiable {
    let id: UUID
    let note_id: UUID
    let user_id: UUID
    let content: String
    let created_at: Date?
    let updated_at: Date?
    
    // Profile info joined via foreign key
    var profiles: ProfileData? = nil
    
    struct ProfileData: Codable {
        let username: String?
        let display_name: String?
        let profile_photo_url: String?
    }
}
