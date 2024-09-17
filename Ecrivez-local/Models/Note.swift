//
//  Note.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI
import CoreLocation

struct Note: Identifiable, Codable {
    

    var id = UUID()
    var attributedTextData: Data // Store the attributed text as Data
    var images: [UIImage] = []
    var category: Category
    var date: Date? = nil
    var location: CLLocation? = nil

    var attributedText: NSAttributedString {
        get {
            do {
                return try NSAttributedString(data: attributedTextData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            } catch {
                print("Error decoding attributedTextData: \(error)")
                return NSAttributedString(string: "")
            }
        }
        set {
            do {
                attributedTextData = try newValue.data(from: NSRange(location: 0, length: newValue.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            } catch {
                print("Error encoding attributedText: \(error)")
                attributedTextData = Data()
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, attributedTextData, imagesData, category, date, locationData
    }

    // Encode images as Data
    var imagesData: [Data] {
        get {
            images.compactMap { $0.jpegData(compressionQuality: 1.0) }
        }
        set {
            images = newValue.compactMap { UIImage(data: $0) }
        }
    }

    // Location encoding
    var locationData: [String: Double]? {
        get {
            guard let location = location else { return nil }
            return ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
        }
    }

    // Custom encoding and decoding methods
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(attributedTextData, forKey: .attributedTextData)
        try container.encode(imagesData, forKey: .imagesData)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(date, forKey: .date)
        if let locationData = locationData {
            try container.encode(locationData, forKey: .locationData)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        attributedTextData = try container.decode(Data.self, forKey: .attributedTextData)
        let imageDatas = try container.decode([Data].self, forKey: .imagesData)
        images = imageDatas.compactMap { UIImage(data: $0) }
        category = try container.decode(Category.self, forKey: .category)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        if let locationDict = try container.decodeIfPresent([String: Double].self, forKey: .locationData),
           let latitude = locationDict["latitude"],
           let longitude = locationDict["longitude"] {
            location = CLLocation(latitude: latitude, longitude: longitude)
        } else {
            location = nil
        }
    }

    // Custom initializer
    init(id: UUID = UUID(), attributedText: NSAttributedString, images: [UIImage] = [], category: Category, date: Date? = nil, location: CLLocation? = nil) {
        self.id = id
        self.images = images
        self.category = category
        self.date = date
        self.location = location
        do {
            self.attributedTextData = try attributedText.data(from: NSRange(location: 0, length: attributedText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        } catch {
            print("Error encoding attributedText: \(error)")
            self.attributedTextData = Data()
        }
    }
}
