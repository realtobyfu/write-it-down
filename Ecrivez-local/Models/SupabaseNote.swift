//
//  SupabaseNote.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/27/25.
//

import Foundation

struct SupabaseNote: Codable, Identifiable {
    let id: UUID
    let owner_id: UUID
    let category_id: UUID?
    
    // Keep your plain text field if you want:
    let content: String
    
    // New optional RTF field (Base64-encoded string):
    var rtf_content: String?
    
    var date: Date? = nil
    var locationLongitude: Double? = nil
    var locationLatitude: Double? = nil
    var isAnnonymous: Bool?
    
    let colorString: String
    let symbol: String
    
    var profiles: ProfileData? = nil
    
    struct ProfileData: Codable {
        let username: String?
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, owner_id, category_id, content
        case rtf_content        // new!
        case date, locationLongitude, locationLatitude
        case isAnnonymous, colorString, symbol
        case profiles
    }
    
    // Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.owner_id = try container.decode(UUID.self, forKey: .owner_id)
        self.category_id = try container.decodeIfPresent(UUID.self, forKey: .category_id)
        
        self.content = try container.decode(String.self, forKey: .content)
        self.rtf_content = try container.decodeIfPresent(String.self, forKey: .rtf_content)
        
        // ... existing date / location / isAnnonymous
        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.date = formatter.date(from: dateString)
        } else {
            self.date = nil
        }
        self.isAnnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnnonymous)
        self.locationLongitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
        self.locationLatitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
        
        self.colorString = try container.decode(String.self, forKey: .colorString)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        
        self.profiles = try container.decodeIfPresent(ProfileData.self, forKey: .profiles)
    }
    
    // Convenience init for "update/insert" usage
    init(id: UUID,
         owner_id: UUID,
         category_id: UUID?,
         content: String,
         rtf_content: String?,      // new param
         date: Date?,
         locationLongitude: Double?,
         locationLatitude: Double?,
         colorString: String,
         symbol: String,
         isAnnonymous: Bool
    ) {
        self.id = id
        self.owner_id = owner_id
        self.category_id = category_id
        
        self.content = content
        self.rtf_content = rtf_content
        
        self.date = date
        if let lat = locationLatitude, let lon = locationLongitude {
            self.locationLatitude = lat
            self.locationLongitude = lon
        }
        self.isAnnonymous = isAnnonymous
        
        self.colorString = colorString
        self.symbol = symbol
        
        self.profiles = nil
    }
}

