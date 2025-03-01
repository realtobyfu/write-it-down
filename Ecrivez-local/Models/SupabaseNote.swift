//
//  SupabaseNote.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/27/25.
//

import Foundation
import CoreLocation

struct SupabaseNote: Codable, Identifiable {
    let id: UUID
    let owner_id: UUID
    
    let category_id: UUID?
    let content: String
    var rtf_content: String?
    
    var date: Date?
    var locationLongitude: String?
    var locationLatitude: String?
    
    var isAnnonymous: Bool?  // <-- This was already declared
    
    let colorString: String
    let symbol: String
    
    var profiles: ProfileData? = nil
    
    struct ProfileData: Codable {
        let username: String?
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, owner_id, category_id
        case content, rtf_content
        case date, locationLongitude, locationLatitude
        case isAnnonymous
        case colorString, symbol
        case profiles
    }
    
    // MARK: - Decoder for fetching from DB
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.owner_id = try container.decode(UUID.self, forKey: .owner_id)
        self.category_id = try container.decodeIfPresent(UUID.self, forKey: .category_id)
        
        self.content = try container.decode(String.self, forKey: .content)
        self.rtf_content = try container.decodeIfPresent(String.self, forKey: .rtf_content)
        
        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.date = formatter.date(from: dateString)
        } else {
            self.date = nil
        }
        
        self.locationLongitude = try container.decodeIfPresent(String.self, forKey: .locationLongitude)
        self.locationLatitude = try container.decodeIfPresent(String.self, forKey: .locationLatitude)
        self.isAnnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnnonymous)
        
        self.colorString = try container.decode(String.self, forKey: .colorString)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        
        self.profiles = try container.decodeIfPresent(ProfileData.self, forKey: .profiles)
    }
    
    // MARK: - Convenience init for uploading to DB
    init(id: UUID,
         owner_id: UUID,
         category_id: UUID?,
         content: String,
         rtf_content: String?,
         date: Date?,
         locationLatitude: String?,
         locationLongitude: String?,
         colorString: String,
         symbol: String,
         isAnnonymous: Bool?
    ) {
        self.id = id
        self.owner_id = owner_id
        self.category_id = category_id
        self.content = content
        self.rtf_content = rtf_content
        self.date = date
        
        self.locationLongitude = locationLongitude
        self.locationLatitude = locationLatitude
        self.isAnnonymous = isAnnonymous
        
        self.colorString = colorString
        self.symbol = symbol
        
        self.profiles = nil
    }
}


extension SupabaseNote {
    var location: CLLocation? {
//        print(CLLocation(latitude: Double(locationLatitude), longitude: Double(locationLatitude)))
        guard
            let latString = locationLatitude,
            let lonString = locationLongitude,
            let lat = Double(latString),
            let lon = Double(lonString)
        else {
            print("cannot find the location")
            return nil
        }
        return CLLocation(latitude: lat, longitude: lon)
    }
}
