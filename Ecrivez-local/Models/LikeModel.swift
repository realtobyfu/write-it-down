//
//  LikeModel.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/5/25.
//

import Foundation

struct LikeModel: Codable, Identifiable {
    
    let id: UUID
    let note_id: UUID
    let user_id: UUID
    let created_at: Date?
    
    // This makes it easy to fetch profile info with the like
    var profiles: ProfileData? = nil
    
    struct ProfileData: Codable {
        let username: String?
        let display_name: String?
        let profile_photo_url: String?
    }

}
