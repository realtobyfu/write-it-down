//
//  Category+CoreDataProperties.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 10/21/24.
//
//

import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var colorString: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var symbol: String?
    @NSManaged public var relationship: NSSet?

}

// MARK: Generated accessors for relationship
extension Category {

    @objc(addRelationshipObject:)
    @NSManaged public func addToRelationship(_ value: Note)

    @objc(removeRelationshipObject:)
    @NSManaged public func removeFromRelationship(_ value: Note)

    @objc(addRelationship:)
    @NSManaged public func addToRelationship(_ values: NSSet)

    @objc(removeRelationship:)
    @NSManaged public func removeFromRelationship(_ values: NSSet)

}

extension Category : Identifiable {

}
