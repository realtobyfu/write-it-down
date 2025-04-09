//
//  DataController.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 10/22/24.
//


import CoreData
import Foundation

class DataController: ObservableObject {

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

