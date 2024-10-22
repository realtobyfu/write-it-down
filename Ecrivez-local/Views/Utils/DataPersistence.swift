//
//  DataPersistence.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 10/12/24.
//

//import Foundation
//
//// Function to save notes to a JSON file
//func saveNotes(_ notes: [Note]) {
//    let encoder = JSONEncoder()
//    encoder.outputFormatting = .prettyPrinted
//    
//    do {
//        let data = try encoder.encode(notes)
//        
//    
//        let url = getDocumentsDirectory().appendingPathComponent("notes.json")
//        try data.write(to: url)
//        print("Notes saved successfully!")
//    } catch {
//        print("Failed to save notes: \(error)")
//    }
//}
//
//// Function to load notes from a JSON file
//func loadNotes() -> [Note] {
//    let url = getDocumentsDirectory().appendingPathComponent("notes.json")
//    
//    do {
//        let data = try Data(contentsOf: url)
//        let decoder = JSONDecoder()
//        let notes = try decoder.decode([Note].self, from: data)
//        return notes
//    } catch {
//        print("Failed to load notes: \(error)")
//        return []
//    }
//}
//
//func saveCategories(_ categories: [Category]) {
//    let encoder = JSONEncoder()
//    encoder.outputFormatting = .prettyPrinted
//    
//    do {
//        let data = try encoder.encode(categories)
//        let url = getDocumentsDirectory().appendingPathComponent("categories.json")
//        try data.write(to: url)
//        print("Categories saved successfully!")
//    } catch {
//        print("Failed to save categories: \(error)")
//    }
//}
//
//// Function to load categories from a JSON file
//func loadCategories() -> [Category] {
//    let url = getDocumentsDirectory().appendingPathComponent("categories.json")
//    
//    do {
//        let data = try Data(contentsOf: url)
//        let decoder = JSONDecoder()
//        let categories = try decoder.decode([Category].self, from: data)
//        return categories
//    } catch {
//        print("Failed to load categories: \(error)")
//        return []
//    }
//}
//
//
//
//// Helper function to get the Documents directory URL
//func getDocumentsDirectory() -> URL {
//    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//    return paths[0]
//}
