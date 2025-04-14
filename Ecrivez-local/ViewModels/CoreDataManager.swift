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
    
    let container = NSPersistentContainer(name: "Model")

    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            } else {
                checkAndPopulateDefaultCategories(context: self.container.viewContext)
            }
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
        category.symbol = categoryData.symbol
        category.colorString = categoryData.color
        category.name = categoryData.name
    }
    
    do {
        try context.save()
    } catch {
        print("Failed to save default categories: \(error)")
    }
}

