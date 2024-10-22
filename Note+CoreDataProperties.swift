//
//  Note+CoreDataProperties.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 10/21/24.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var attributedTextData: Data?
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var imageData: NSObject?
    @NSManaged public var locationLatitude: Double
    @NSManaged public var locationLongitude: Double
    @NSManaged public var relationship: Category?

}

extension Note : Identifiable {

}
