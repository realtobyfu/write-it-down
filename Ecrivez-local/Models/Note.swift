//
//  Note.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

// Note+Extensions.swift
import Foundation
import UIKit
import CoreLocation

extension Note {
    var attributedText: NSAttributedString {
        get {
            guard let data = self.attributedTextData else {
                return NSAttributedString(string: "")
            }
            do {
                return try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
            } catch {
                print("Error decoding attributedTextData: \(error)")
                return NSAttributedString(string: "")
            }
        }
        set {
            do {
                self.attributedTextData = try newValue.data(
                    from: NSRange(location: 0, length: newValue.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
            } catch {
                print("Error encoding attributedText: \(error)")
                self.attributedTextData = Data()
            }
        }
    }

    var location: CLLocation? {
        get {
            if let latitudeValue = self.locationLatitude as? NSDecimalNumber,
               let longitudeValue = self.locationLongitude as? NSDecimalNumber {
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
}
