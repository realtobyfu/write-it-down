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
    var locationName: String?
    var locationLocality: String?  // Add new field
    var locationLongitude: String?
    var locationLatitude: String?
    var isAnonymous: Bool?
    let colorString: String
    let symbol: String
    var archived_content: String?
    var profiles: ProfileData? = nil
    
    struct ProfileData: Codable {
        let username: String?
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, owner_id, category_id
        case content, rtf_content, archived_content
        case date, locationName, locationLocality, locationLongitude, locationLatitude
        case isAnonymous
        case colorString, symbol
        case profiles
    }
    
    // MARK: - Decoder for fetching from DB
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.owner_id = try container.decode(UUID.self, forKey: .owner_id)
        self.category_id = try container.decodeIfPresent(UUID.self, forKey: .category_id)
        self.archived_content = try container.decodeIfPresent(String.self, forKey: .archived_content)
        self.content = try container.decode(String.self, forKey: .content)
        self.rtf_content = try container.decodeIfPresent(String.self, forKey: .rtf_content)
        
        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.date = formatter.date(from: dateString)
        } else {
            self.date = nil
        }
        
        self.locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        self.locationLocality = try container.decodeIfPresent(String.self, forKey: .locationLocality)
        self.locationLongitude = try container.decodeIfPresent(String.self, forKey: .locationLongitude)
        self.locationLatitude = try container.decodeIfPresent(String.self, forKey: .locationLatitude)
        self.isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous)
        
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
         archived_content: String?,
         date: Date?,
         locationName: String?,
         locationLocality: String?,
         locationLatitude: String?,
         locationLongitude: String?,
         colorString: String,
         symbol: String,
         isAnonymous: Bool?
    ) {
        self.id = id
        self.owner_id = owner_id
        self.category_id = category_id
        self.content = content
        self.rtf_content = rtf_content
        self.archived_content = archived_content
        self.date = date
        self.locationName = locationName
        self.locationLocality = locationLocality
        self.locationLongitude = locationLongitude
        self.locationLatitude = locationLatitude
        self.isAnonymous = isAnonymous
        self.colorString = colorString
        self.symbol = symbol
        self.profiles = nil
    }
}

extension SupabaseNote {
    var location: CLLocation? {
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
    
    // Add a computed property to consistently determine the display name based on the same rule
    var displayLocationName: String {
        if let name = locationName, name.count < 12 {
            return name
        } else if let locality = locationLocality, !locality.isEmpty {
            return locality
        } else {
            return locationName ?? ""
        }
    }
}
