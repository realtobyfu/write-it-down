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

extension Note {
    var attributedText: NSAttributedString {
        get {
            // make sure that this is preserving the font
            guard let data = self.attributedTextData else {
                return NSAttributedString(string: "")
            }
            
            // decodeRTF
            do {
                return try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
            } catch {
                print("Decode RTF error: \(error)")
                return NSAttributedString()
            }
        }
        set {
            do {
                // make sure that this conversion is working for the fonts/
                let rtfData = try newValue.data(
                    from: NSRange(location: 0, length: newValue.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
                self.attributedTextData = rtfData
            } catch {
                print("Encode RTF error: \(error)")
                self.attributedTextData = nil
            }
        }
    }

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
        // Convert the raw RTF Data into a base64 string
        let rtfString = self.attributedTextData?.base64EncodedString()
        
        print("longitude: \(String(describing: self.locationLongitude))")
        print("latitude: \(String(describing: self.locationLatitude))")
        
        return SupabaseNote(
            id: self.id ?? UUID(),
            owner_id: ownerID,
            category_id: self.category?.id,
            // Plain text for quick reads/fallback
            content: self.attributedText.string,
            // Full RTF as base64
            rtf_content: rtfString,
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
