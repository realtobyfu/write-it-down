//
//  SyncedNote.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/16/25.
//

import Foundation

// SyncedCategory.swift
struct SyncedCategory: Codable, Identifiable {
    let id: UUID
    let owner_id: UUID
    let name: String
    let symbol: String
    let colorString: String
    let index: Int
    let created_at: Date?
    let last_modified: Date?
}

// Updated SyncedNote.swift to match your Supabase table
struct SyncedNote: Codable, Identifiable {
    let id: UUID
    let owner_id: UUID
    let category_id: UUID?
    let content: String
    let attributedTextData: String? // Changed from archived_content to match your table
    let date: Date?
    let locationName: String?
    let locationLocality: String?
    let locationLatitude: String?
    let locationLongitude: String?
    let colorString: String
    let symbol: String
    let last_modified: Date?
    let is_deleted: Bool
    let created_at: Date?
    let isAnonymous: Bool? // Added to match your table
    let isPublic: Bool? // Added to match your table
    
    func toAttributedString() -> NSAttributedString {
        if let attributedData = attributedTextData,
           let data = Data(base64Encoded: attributedData) {
            do {
                return try NSAttributedString(data: data, format: .archivedData)
            } catch {
                print("Error decoding rich text: \(error)")
            }
        }
        
        return NSAttributedString(string: content)
    }
}
