//
//  Note.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

// Note+Extensions.swift/Users/realtobyfu/Documents/Ecrivez-local/Ecrivez-local/NoteRepository.swift
import Foundation
import UIKit
import CoreLocation
import RichTextKit

extension Note {
    var attributedText: NSAttributedString {
        get {
            guard let data = self.attributedTextData else {
                return NSAttributedString(string: "")
            }
            
            do {
                // Use RichTextKit's initializer with format
                return try NSAttributedString(data: data, format: .archivedData)
            } catch {
                print("Decode error: \(error)")
                return NSAttributedString()
            }
        }
        set {
            do {
                // Use richTextData(for:) extension method
                self.attributedTextData = try newValue.richTextData(for: .archivedData)
            } catch {
                print("Encode error: \(error)")
                self.attributedTextData = nil
            }
        }
    }
}

extension Note {
    var location: CLLocation? {
        get {
            if let latitudeValue = self.locationLatitude,
               let longitudeValue = self.locationLongitude {
                return CLLocation(latitude: latitudeValue.doubleValue, longitude: longitudeValue.doubleValue)
            }
            return nil
        }
        set {
            if let newLocation = newValue {
                self.locationLatitude = NSDecimalNumber(value: newLocation.coordinate.latitude)
                self.locationLongitude = NSDecimalNumber(value: newLocation.coordinate.longitude)
            } else {
                self.locationLatitude = nil
                self.locationLongitude = nil
            }
        }
    }
    
    // Update the placeName property with logic for landmark vs locality
    var placeName: String {
        get {
            // If landmark (locationName) is less than 12 chars, use it
            // Otherwise fall back to locality if available
            if let name = locationName, name.count < 12 {
                return name
            } else if let locality = locationLocality, !locality.isEmpty {
                return locality
            } else {
                return locationName ?? ""
            }
        }
        set { locationName = newValue }
    }
    
    // Add a new computed property for direct access to landmark
    var landmark: String {
        get { locationName ?? "" }
        set { locationName = newValue }
    }
    
    // Add a new computed property for direct access to locality
    var locality: String {
        get { locationLocality ?? "" }
        set { locationLocality = newValue }
    }

}


extension Note {
    func toSupabaseNote(ownerID: UUID) -> SupabaseNote {
        // Get plain text for searching
        let plainText = self.attributedText.string
        
        // Get archived data with proper error handling
        var base64Archived: String? = nil
        do {
            
            let archivedData = try self.attributedText.richTextData(for: .archivedData)
            let base64Archived = archivedData.base64EncodedString()

        } catch {
            print("Failed to get archived data: \(error)")
            // Continue with nil archived data - will fall back to plain text
        }
        
        return SupabaseNote(
            id: self.id ?? UUID(),
            owner_id: ownerID,
            category_id: self.category?.id,
            content: plainText,
            rtf_content: nil,  // No longer using RTF
            archived_content: base64Archived,
            date: self.date,
            locationName: self.landmark,
            locationLocality: self.locality,
            locationLatitude: self.locationLatitude?.stringValue,
            locationLongitude: self.locationLongitude?.stringValue,
            colorString: self.category?.colorString ?? "",
            symbol: self.category?.symbol ?? "",
            isAnnonymous: self.isAnnonymous
        )
    }
}
