//
//  Ecrivez_localApp.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 7/22/24.
//
import SwiftUI
import CoreData

@main
struct NoteApp: App {
    
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
    
}
