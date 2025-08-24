//
//  CategoryUUIDGenerator.swift
//  Write-It-Down
//
//  Created on 8/21/25.
//

import Foundation
import CryptoKit

class CategoryUUIDGenerator {
    // Namespace UUID for category generation (a fixed UUID for our app's categories)
    private static let namespaceUUID = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
    
    /// Generates a deterministic UUID for a category based on its properties
    /// - Parameters:
    ///   - name: The category name
    ///   - color: The category color string
    ///   - symbol: The category symbol
    /// - Returns: A deterministic UUID that will always be the same for the same input
    static func generateDeterministicUUID(name: String, color: String, symbol: String) -> UUID {
        // Create a unique string from the category properties
        let uniqueString = "\(name)|\(color)|\(symbol)".lowercased()
        
        // Generate UUID v5 using SHA-1 hash
        return generateUUIDv5(namespace: namespaceUUID, name: uniqueString)
    }
    
    /// Generates a UUID v5 (namespace + name based) according to RFC 4122
    private static func generateUUIDv5(namespace: UUID, name: String) -> UUID {
        var namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Data($0) }
        let nameData = name.data(using: .utf8)!
        namespaceBytes.append(nameData)
        
        // Use SHA-1 for UUID v5
        let hash = Insecure.SHA1.hash(data: namespaceBytes)
        let hashBytes = Array(hash)
        
        // Set version (5) and variant bits according to RFC 4122
        var uuid = hashBytes[0..<16]
        uuid[6] = (uuid[6] & 0x0F) | 0x50  // Version 5
        uuid[8] = (uuid[8] & 0x3F) | 0x80  // Variant 10
        
        // Create UUID from bytes
        let uuidBytes = (
            uuid[0], uuid[1], uuid[2], uuid[3],
            uuid[4], uuid[5], uuid[6], uuid[7],
            uuid[8], uuid[9], uuid[10], uuid[11],
            uuid[12], uuid[13], uuid[14], uuid[15]
        )
        
        return UUID(uuid: uuidBytes)
    }
    
    /// Checks if a given UUID is a default category UUID
    static func isDefaultCategoryUUID(_ id: UUID) -> Bool {
        // Check if this UUID matches any of the default categories
        for categoryData in StyleManager.defaultCategories {
            let generatedUUID = generateDeterministicUUID(
                name: categoryData.name,
                color: categoryData.color,
                symbol: categoryData.symbol
            )
            if generatedUUID == id {
                return true
            }
        }
        return false
    }
}