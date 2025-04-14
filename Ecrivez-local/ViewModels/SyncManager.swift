////
////  StyleManager.swift
////  Write-It-Down
////
////  Created on 4/9/25.
////
//
//import SwiftUI
//import Supabase
//import CoreData
//
//@MainActor
//class SyncManager: ObservableObject {
//    static let shared = SyncManager()
//    
//    @Published var isSyncing = false
//    @Published var lastSyncTime: Date?
//    @Published var syncEnabled = UserDefaults.standard.bool(forKey: "syncEnabled") {
//        didSet {
//            UserDefaults.standard.set(syncEnabled, forKey: "syncEnabled")
//        }
//    }
//    
//    private let client = SupabaseManager.shared.client
//    
//    private init() {}
//    
//    // Sync all local notes to Supabase
//    func performFullSync(context: NSManagedObjectContext) async throws {
//        guard syncEnabled else { return }
//        guard let userID = try? await client.auth.user().id else {
//            throw SyncError.notAuthenticated
//        }
//        
//        isSyncing = true
//        defer { isSyncing = false }
//        
//        // 1. Fetch all local notes
//        let localNotes = try fetchAllLocalNotes(context: context)
//        
//        // 2. Fetch all remote notes
//        let remoteNotes = try await fetchAllRemoteNotes()
//        
//        // 3. Determine which notes need to be uploaded, updated, or deleted
//        let localIDsSet = Set(localNotes.compactMap { $0.id })
//        let remoteIDsSet = Set(remoteNotes.map { $0.id })
//        
//        // Notes to upload (exist locally but not remotely)
//        let notesToUpload = localNotes.filter { note in
//            guard let id = note.id else { return false }
//            return !remoteIDsSet.contains(id)
//        }
//        
//        // Notes to potentially update (exist both locally and remotely)
//        let notesToUpdate = localNotes.filter { note in
//            guard let id = note.id else { return false }
//            return remoteIDsSet.contains(id)
//        }
//        
//        // Notes to download (exist remotely but not locally)
//        let notesToDownload = remoteNotes.filter { note in
//            return !localIDsSet.contains(note.id)
//        }
//        
//        // 4. Perform the sync operations
//        try await uploadNotes(notesToUpload, userID: userID)
//        try await updateNotes(notesToUpdate, remoteNotes: remoteNotes, userID: userID)
//        try await downloadNotes(notesToDownload, context: context)
//        
//        // 5. Update last sync time
//        lastSyncTime = Date()
//        UserDefaults.standard.set(lastSyncTime, forKey: "lastSyncTime")
//    }
//    
//    private func fetchAllLocalNotes(context: NSManagedObjectContext) throws -> [Note] {
//        let request = NSFetchRequest<Note>(entityName: "Note")
//        return try context.fetch(request)
//    }
//    
//    private func fetchAllRemoteNotes() async throws -> [SyncedNote] {
//        return try await client
//            .from("synced_notes")
//            .select()
//            .execute()
//            .value
//    }
//    
//    private func uploadNotes(_ notes: [Note], userID: UUID) async throws {
//        for note in notes {
//            let syncedNote = note.toSyncedNote(ownerID: userID)
//            try await client
//                .from("synced_notes")
//                .insert(syncedNote)
//                .execute()
//        }
//    }
//    
//    private func updateNotes(_ localNotes: [Note], remoteNotes: [SyncedNote], userID: UUID) async throws {
//        for localNote in localNotes {
//            guard let id = localNote.id else { continue }
//            
//            // Find matching remote note
//            if let remoteNote = remoteNotes.first(where: { $0.id == id }) {
//                // Compare last modified timestamps to determine which version is newer
//                let localTimestamp = localNote.lastModified ?? Date.distantPast
//                let remoteTimestamp = remoteNote.last_modified ?? Date.distantPast
//                
//                if localTimestamp > remoteTimestamp {
//                    // Local note is newer, update remote
//                    let syncedNote = localNote.toSyncedNote(ownerID: userID)
//                    try await client
//                        .from("synced_notes")
//                        .update(syncedNote)
//                        .eq("id", value: id)
//                        .execute()
//                }
//            }
//        }
//    }
//    
//    private func downloadNotes(_ remoteNotes: [SyncedNote], context: NSManagedObjectContext) async throws {
//        for remoteNote in remoteNotes {
//            // Create new local note
//            let newNote = Note(context: context)
//            
//            // Populate the note with remote data
//            newNote.id = remoteNote.id
//            newNote.attributedText = remoteNote.toAttributedString()
//            newNote.date = remoteNote.date
//            newNote.locationName = remoteNote.locationName
//            newNote.locationLocality = remoteNote.locationLocality
//            
//            if let lat = remoteNote.locationLatitude, let lon = remoteNote.locationLongitude,
//               let latDouble = Double(lat), let lonDouble = Double(lon) {
//                newNote.locationLatitude = NSDecimalNumber(value: latDouble)
//                newNote.locationLongitude = NSDecimalNumber(value: lonDouble)
//            }
//            
//            // Find or create matching category
//            if let categoryID = remoteNote.category_id {
//                let categoryRequest = NSFetchRequest<Category>(entityName: "Category")
//                categoryRequest.predicate = NSPredicate(format: "id == %@", categoryID as CVarArg)
//                
//                if let categories = try? context.fetch(categoryRequest), let category = categories.first {
//                    newNote.category = category
//                } else {
//                    // Category doesn't exist locally, create default or placeholder
//                    let newCategory = Category(context: context)
//                    newCategory.id = categoryID
//                    newCategory.colorString = remoteNote.colorString
//                    newCategory.symbol = remoteNote.symbol
//                    newCategory.name = "Synced Category"
//                    
//                    newNote.category = newCategory
//                }
//            }
//            
//            newNote.lastModified = remoteNote.last_modified
//        }
//        
//        try context.save()
//    }
//    
//    enum SyncError: Error {
//        case notAuthenticated
//        case networkError
//        case dataError
//    }
//}
