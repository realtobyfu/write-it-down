//
//  StyleManager.swift
//  Write-It-Down
//
//  Created on 4/9/25.
//

import SwiftUI
import Supabase
import CoreData

@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncEnabled = UserDefaults.standard.bool(forKey: "syncEnabled") {
        didSet {
            UserDefaults.standard.set(syncEnabled, forKey: "syncEnabled")
        }
    }
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    // Main sync function
    func performFullSync(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. First sync categories
        try await syncCategories(context: context, userID: userID)
        
        // 2. Then sync notes (which may reference categories)
        try await syncNotes(context: context, userID: userID)
        
        // 3. Update last sync time
        lastSyncTime = Date()
        UserDefaults.standard.set(lastSyncTime, forKey: "lastSyncTime")
    }
    
    // Category synchronization
    private func syncCategories(context: NSManagedObjectContext, userID: UUID) async throws {
        // 1. Fetch all local categories
        let localCategories = try fetchAllLocalCategories(context: context)
        
        // 2. Fetch all remote categories
        let remoteCategories = try await fetchAllRemoteCategories()
        
        // 3. Determine which categories need to be uploaded, updated, or downloaded
        let localIDsSet = Set(localCategories.compactMap { $0.id })
        let remoteIDsSet = Set(remoteCategories.map { $0.id })
        
        // Categories to upload (exist locally but not remotely)
        let categoriesToUpload = localCategories.filter { category in
            guard let id = category.id else { return false }
            return !remoteIDsSet.contains(id)
        }
        
        // Categories to potentially update (exist both locally and remotely)
        let categoriesToUpdate = localCategories.filter { category in
            guard let id = category.id else { return false }
            return remoteIDsSet.contains(id)
        }
        
        // Categories to download (exist remotely but not locally)
        let categoriesToDownload = remoteCategories.filter { category in
            return !localIDsSet.contains(category.id)
        }
        
        // 4. Perform the sync operations for categories
        try await uploadCategories(categoriesToUpload, userID: userID)
        try await updateCategories(categoriesToUpdate, remoteCategories: remoteCategories, userID: userID)
        try await downloadCategories(categoriesToDownload, context: context)
    }
    
    // Note synchronization (after categories are synced)
    private func syncNotes(context: NSManagedObjectContext, userID: UUID) async throws {
        // 1. Fetch all local notes
        let localNotes = try fetchAllLocalNotes(context: context)
        
        // 2. Fetch all remote notes
        let remoteNotes = try await fetchAllRemoteNotes()
        
        // 3. Determine which notes need to be uploaded, updated, or downloaded
        let localIDsSet = Set(localNotes.compactMap { $0.id })
        let remoteIDsSet = Set(remoteNotes.map { $0.id })
        
        // Notes to upload (exist locally but not remotely)
        let notesToUpload = localNotes.filter { note in
            guard let id = note.id else { return false }
            return !remoteIDsSet.contains(id)
        }
        
        // Notes to potentially update (exist both locally and remotely)
        let notesToUpdate = localNotes.filter { note in
            guard let id = note.id else { return false }
            return remoteIDsSet.contains(id)
        }
        
        // Notes to download (exist remotely but not locally)
        let notesToDownload = remoteNotes.filter { note in
            return !localIDsSet.contains(note.id)
        }
        
        // 4. Perform the sync operations for notes
        try await uploadNotes(notesToUpload, userID: userID)
        try await updateNotes(notesToUpdate, remoteNotes: remoteNotes, userID: userID)
        try await downloadNotes(notesToDownload, context: context)
    }
    
    // MARK: - Category Methods
    
    private func fetchAllLocalCategories(context: NSManagedObjectContext) throws -> [Category] {
        let request = NSFetchRequest<Category>(entityName: "Category")
        return try context.fetch(request)
    }
    
    private func fetchAllRemoteCategories() async throws -> [SyncedCategory] {
        return try await client
            .from("synced_categories")
            .select()
            .execute()
            .value
    }
    
    private func uploadCategories(_ categories: [Category], userID: UUID) async throws {
        for category in categories {
            let syncedCategory = category.toSyncedCategory(ownerID: userID)
            try await client
                .from("synced_categories")
                .insert(syncedCategory)
                .execute()
        }
    }
    
    private func updateCategories(_ localCategories: [Category], remoteCategories: [SyncedCategory], userID: UUID) async throws {
        for localCategory in localCategories {
            guard let id = localCategory.id else { continue }
            
            // Find matching remote category
            if let remoteCategory = remoteCategories.first(where: { $0.id == id }) {
                // For categories, we can simply check if names, symbols, or colors have changed
                // We'll assume that if any of these have changed, we should update
                if localCategory.name != remoteCategory.name ||
                   localCategory.symbol != remoteCategory.symbol ||
                   localCategory.colorString != remoteCategory.colorString {
                    // Local category is different, update remote
                    let syncedCategory = localCategory.toSyncedCategory(ownerID: userID)
                    try await client
                        .from("synced_categories")
                        .update(syncedCategory)
                        .eq("id", value: id)
                        .execute()
                }
            }
        }
    }
    
    private func downloadCategories(_ remoteCategories: [SyncedCategory], context: NSManagedObjectContext) async throws {
        // Get the current user ID to ensure we only download our own categories
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        for remoteCategory in remoteCategories {
            // Only process categories that belong to the current user
            guard remoteCategory.owner_id == userID else {
                print("Skipping category with different owner: \(remoteCategory.id)")
                continue
            }
            
            // Check if a category with this ID already exists locally
            let request = NSFetchRequest<Category>(entityName: "Category")
            request.predicate = NSPredicate(format: "id == %@", remoteCategory.id as CVarArg)
            
            let existingCategories = try context.fetch(request)
            
            if let existingCategory = existingCategories.first {
                // Update existing category
                existingCategory.name = remoteCategory.name
                existingCategory.symbol = remoteCategory.symbol
                existingCategory.colorString = remoteCategory.colorString
                existingCategory.index = Int16(remoteCategory.index)
            } else {
                // Create new local category
                let newCategory = Category(context: context)
                newCategory.id = remoteCategory.id
                newCategory.name = remoteCategory.name
                newCategory.symbol = remoteCategory.symbol
                newCategory.colorString = remoteCategory.colorString
                newCategory.index = Int16(remoteCategory.index)
            }
        }
        
        try context.save()
    }

    // MARK: - Note Methods
    
    private func fetchAllLocalNotes(context: NSManagedObjectContext) throws -> [Note] {
        let request = NSFetchRequest<Note>(entityName: "Note")
        return try context.fetch(request)
    }
    
    private func fetchAllRemoteNotes() async throws -> [SyncedNote] {
        return try await client
            .from("synced_notes")
            .select()
            .execute()
            .value
    }
    
    private func uploadNotes(_ notes: [Note], userID: UUID) async throws {
        for note in notes {
            let syncedNote = note.toSyncedNote(ownerID: userID)
            try await client
                .from("synced_notes")
                .insert(syncedNote)
                .execute()
        }
    }
    
    private func updateNotes(_ localNotes: [Note], remoteNotes: [SyncedNote], userID: UUID) async throws {
        for localNote in localNotes {
            guard let id = localNote.id else { continue }
            
            // Find matching remote note
            if let remoteNote = remoteNotes.first(where: { $0.id == id }) {
                // Always update remote from local since we can't reliably
                // determine which is newer without lastModified
                let syncedNote = localNote.toSyncedNote(ownerID: userID)
                try await client
                    .from("synced_notes")
                    .update(syncedNote)
                    .eq("id", value: id)
                    .execute()
            }
        }
    }

    
    private func downloadNotes(_ remoteNotes: [SyncedNote], context: NSManagedObjectContext) async throws {
        
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }

        
        for remoteNote in remoteNotes {
            // Check if a note with this ID already exists locally
            let request = NSFetchRequest<Note>(entityName: "Note")
            request.predicate = NSPredicate(format: "id == %@", remoteNote.id as CVarArg)
            
            let existingNotes = try context.fetch(request)
            
            var noteToUpdate: Note
            
            if let existingNote = existingNotes.first {
                // Compare timestamps to determine which is newer
                let localTimestamp = existingNote.lastModified ?? Date.distantPast
                let remoteTimestamp = remoteNote.last_modified ?? Date.distantPast
                
                if remoteTimestamp <= localTimestamp {
                    // Local note is newer or same age, skip this note
                    continue
                }
                
                // Remote note is newer, update local note
                noteToUpdate = existingNote
            } else {
                // Create new local note
                noteToUpdate = Note(context: context)
                noteToUpdate.id = remoteNote.id
            }
            
            // Update note properties
            noteToUpdate.attributedText = remoteNote.toAttributedString()
            noteToUpdate.date = remoteNote.date
            noteToUpdate.locationName = remoteNote.locationName
            noteToUpdate.locationLocality = remoteNote.locationLocality
            
            if let lat = remoteNote.locationLatitude, let lon = remoteNote.locationLongitude,
               let latDouble = Double(lat), let lonDouble = Double(lon) {
                noteToUpdate.locationLatitude = NSDecimalNumber(value: latDouble)
                noteToUpdate.locationLongitude = NSDecimalNumber(value: lonDouble)
            }
            
            noteToUpdate.lastModified = remoteNote.last_modified
            
            // Set isPublic and isAnonymous properties
            noteToUpdate.isPublic = remoteNote.isPublic ?? false
            noteToUpdate.isAnonymous = remoteNote.isAnonymous ?? false
            
            // Link to category if available
            if let categoryID = remoteNote.category_id {
                let categoryRequest = NSFetchRequest<Category>(entityName: "Category")
                categoryRequest.predicate = NSPredicate(format: "id == %@", categoryID as CVarArg)
                
                if let categories = try? context.fetch(categoryRequest), let category = categories.first {
                    noteToUpdate.category = category
                }
             }
        }
        
        try context.save()
    }
    
    enum SyncError: Error {
        case notAuthenticated
        case networkError
        case dataError
    }
}


extension SyncManager {
    // Add to SyncManager.swift
    func uploadData(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. Sync categories first
        try await uploadCategories(context: context, userID: userID)
        
        // 2. Then sync notes
        try await uploadNotes(context: context, userID: userID)
    }

    func downloadData(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. Download categories first
        try await downloadCategoriesFromRemote(context: context)
        
        // 2. Then download notes
        try await downloadNotesFromRemote(context: context)
    }

    // Helper methods
    private func uploadCategories(context: NSManagedObjectContext, userID: UUID) async throws {
        // Fetch all local categories
        let localCategories = try fetchAllLocalCategories(context: context)
        
        // Fetch all remote categories that belong to this user
        let remoteCategories = try await fetchAllRemoteCategories()
        let userRemoteCategories = remoteCategories.filter { $0.owner_id == userID }
        
        // Get the IDs of remote categories
        let remoteIDsSet = Set(userRemoteCategories.map { $0.id })
        
        // Upload new categories (exist locally but not remotely)
        let categoriesToUpload = localCategories.filter { category in
            guard let id = category.id else { return false }
            return !remoteIDsSet.contains(id)
        }
        
        try await uploadCategories(categoriesToUpload, userID: userID)
        
        // Update existing categories
        let categoriesToUpdate = localCategories.filter { category in
            guard let id = category.id else { return false }
            return remoteIDsSet.contains(id)
        }
        
        try await updateCategories(categoriesToUpdate, remoteCategories: userRemoteCategories, userID: userID)
    }

    private func uploadNotes(context: NSManagedObjectContext, userID: UUID) async throws {
        // Fetch all local notes
        let localNotes = try fetchAllLocalNotes(context: context)
        
        // Fetch all remote notes that belong to this user
        let remoteNotes = try await fetchAllRemoteNotes()
        let userRemoteNotes = remoteNotes.filter { $0.owner_id == userID }
        
        // Get the IDs of remote notes
        let remoteIDsSet = Set(userRemoteNotes.map { $0.id })
        
        // Upload new notes (exist locally but not remotely)
        let notesToUpload = localNotes.filter { note in
            guard let id = note.id else { return false }
            return !remoteIDsSet.contains(id)
        }
        
        try await uploadNotes(notesToUpload, userID: userID)
        
        // Update existing notes
        let notesToUpdate = localNotes.filter { note in
            guard let id = note.id else { return false }
            return remoteIDsSet.contains(id)
        }
        
        try await updateNotes(notesToUpdate, remoteNotes: userRemoteNotes, userID: userID)
    }

    private func downloadCategoriesFromRemote(context: NSManagedObjectContext) async throws {
        // Fetch remote categories
        let remoteCategories = try await fetchAllRemoteCategories()
        
        // Download those categories
        try await downloadCategories(remoteCategories, context: context)
    }

    private func downloadNotesFromRemote(context: NSManagedObjectContext) async throws {
        // Fetch remote notes
        let remoteNotes = try await fetchAllRemoteNotes()
        
        // Download those notes
        try await downloadNotes(remoteNotes, context: context)
    }
}
