//
//  DataController.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 10/22/24.
//

import CoreData
import Foundation

//class CoreDataManager: ObservableObject {
//    @MainActor static let shared = CoreDataManager() // Singleton for easier access
//    
//    let container: NSPersistentContainer
//    
//    // MARK: - Customizable storage options
//    private var storeURL: URL {
//        // Customizable store location, useful for testing or multiple stores
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            .appendingPathComponent("Model.sqlite")
//    }
//    
//    // Private init for singleton
//    private init() {
//        container = NSPersistentContainer(name: "Model")
//        
//        // Optionally configure store description
//        let description = NSPersistentStoreDescription(url: storeURL)
//        description.shouldMigrateStoreAutomatically = true
//        description.shouldInferMappingModelAutomatically = true
//        container.persistentStoreDescriptions = [description]
//        
//        container.loadPersistentStores { description, error in
//            if let error = error {
//                print("CoreData failed to load: \(error.localizedDescription)")
//                fatalError("Failed to load Core Data: \(error.localizedDescription)")
//            } else {
//                self.checkAndPopulateDefaultCategories(context: viewContexte)
//            }
//        }
//    }
//
//    @MainActor var viewContext: NSManagedObjectContext {
//          return container.viewContext
//    }

//    // MARK: - Save Context
//    @MainActor func saveContext() {
//        let context = container.viewContext
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                let nsError = error as NSError
//                print("Error saving context: \(nsError)")
//            }
//        }
//    }
//    
//    // MARK: - Background operations
//    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
//        container.performBackgroundTask { context in
//            block(context)
//            // Save if needed within the block
//        }
//    }
//    
//    func checkAndPopulateDefaultCategories(context: NSManagedObjectContext) {
//        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
//    
//        // Check if any categories exist
//        do {
//            let count = try context.count(for: fetchRequest)
//            if count == 0 {
//                // If no categories exist, populate default ones
//                populateDefaultCategories(context: context)
//            }
//        } catch {
//            print("Error checking category count: \(error)")
//        }
//    }
//    
//    func populateDefaultCategories(context: NSManagedObjectContext) {
//        for categoryData in StyleManager.defaultCategories {
//            let category = Category(context: context)
//            category.symbol = categoryData.symbol
//            category.colorString = categoryData.color
//            category.name = categoryData.name
//        }
//    
//        do {
//            try context.save()
//        } catch {
//            print("Failed to save default categories: \(error)")
//        }
//    }
//}
//
//
//
//
import CoreData
import Foundation

class CoreDataManager: ObservableObject {
    
    let container: NSPersistentContainer
    
    // MARK: - Customizable storage options
    private var storeURL: URL {
        // Customizable store location, useful for testing or multiple stores
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Model.sqlite")
    }
    
    init() {
        container = NSPersistentContainer(name: "Model")
        
        // Configure store description with migration options
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Handle the error properly instead of just printing
                print("CoreData failed to load: \(error.localizedDescription)")
                print("Detail: \(error.userInfo)")
                
                // If the error is related to migration or schema mismatch, you could try to recover
                if error.domain == NSCocoaErrorDomain && 
                   (error.code == NSPersistentStoreIncompatibleVersionHashError ||
                    error.code == NSMigrationError ||
                    error.code == NSMigrationMissingSourceModelError ||
                    error.code == 134110) { // The specific error code you're seeing
                    
                    // Try to recover by removing the store file and recreating it
                    print("Attempting to recover from Core Data schema mismatch...")
                    self.resetStore()
                }
            } else {
                self.checkAndPopulateDefaultCategories(context: self.container.viewContext)
            }
        }
    }
    
    // Method to reset the Core Data store when there's a schema mismatch
    private func resetStore() {
        // First, get the persistent store URL
        
        let storeCoordinator = container.persistentStoreCoordinator
        // Remove all persistent stores
        for store in storeCoordinator.persistentStores {
            do {
                try storeCoordinator.remove(store)
            } catch {
                print("Failed to remove store: \(error)")
            }
        }
        
        // Now delete the store file
        do {
            try FileManager.default.removeItem(at: storeURL)
            print("Successfully deleted the Core Data store file")
        } catch {
            print("Failed to delete Core Data store file: \(error)")
        }
        
        // Reload the persistent stores
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Failed to reload persistent stores: \(error)")
            } else {
                print("Successfully reloaded persistent stores")
                self.checkAndPopulateDefaultCategories(context: self.container.viewContext)
            }
        }
    }
    
    func checkAndPopulateDefaultCategories(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()

        // Check if any categories exist
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                // If no categories exist, populate default ones
                populateDefaultCategories(context: context)
            }
        } catch {
            print("Error checking category count: \(error)")
        }
    }
    
    func populateDefaultCategories(context: NSManagedObjectContext) {
        for categoryData in StyleManager.defaultCategories {
            let category = Category(context: context)
            category.id = UUID() // Make sure each category has a unique UUID
            category.symbol = categoryData.symbol
            category.colorString = categoryData.color
            category.name = categoryData.name
        }
        
        do {
            try context.save()
            print("Successfully populated default categories")
        } catch {
            print("Failed to save default categories: \(error)")
        }
    }
    
    // MARK: - Public Utility Methods
    
    // This can be called from your app's debugging UI to forcibly reset the database
    func forceResetDatabase() {
        resetStore()
    }
    
    // Check the health of the Core Data stack
    func checkDatabaseHealth() -> Bool {
        let coordinator = container.persistentStoreCoordinator
        
        if coordinator.persistentStores.isEmpty {
            print("Database health check: No persistent stores")
            return false
        }
        
        // Try a basic fetch to see if the database is operational
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        fetchRequest.fetchLimit = 1
        
        do {
            let _ = try container.viewContext.fetch(fetchRequest)
            print("Database health check: Success")
            return true
        } catch {
            print("Database health check: Failed - \(error.localizedDescription)")
            return false
        }
    }

    // Repair categories with missing UUIDs
    func repairCategories() -> Int {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<Category>(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "id == nil")
        
        do {
            let categoriesWithoutUUID = try context.fetch(fetchRequest)
            print("Found \(categoriesWithoutUUID.count) categories with missing UUIDs")
            
            for category in categoriesWithoutUUID {
                category.id = UUID()
                print("Assigned new UUID \(category.id!) to category: \(category.name ?? "unnamed")")
            }
            
            if categoriesWithoutUUID.count > 0 {
                do {
                    try context.save()
                    print("Successfully saved repaired categories")
                } catch {
                    print("Error saving repaired categories: \(error.localizedDescription)")
                }
            }
            
            return categoriesWithoutUUID.count
        } catch {
            print("Error fetching categories without UUIDs: \(error.localizedDescription)")
            return 0
        }
    }
}

