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
    
    // MARK: - Main Sync Functions
    // Download data from Supabase to Core Data
    func downloadData(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer {
            isSyncing = false
            lastSyncTime = Date()
            UserDefaults.standard.set(lastSyncTime, forKey: "lastDownloadTime")
        }
        
        print("Starting download of categories and notes")
        
        // 1. First download categories
        try await downloadCategoriesFromRemote(context: context)
        
        // 2. Then download notes (which may reference categories)
        try await downloadNotesFromRemote(context: context)
    }
    
    // Upload data from Core Data to Supabase
    func uploadData(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer {
            isSyncing = false
            lastSyncTime = Date()
            UserDefaults.standard.set(lastSyncTime, forKey: "lastUploadTime")
        }
        
        print("Starting upload of categories and notes")
        
        // 1. First upload categories
        try await uploadCategories(context: context, userID: userID)
        
        // 2. Then upload notes
        try await uploadNotes(context: context, userID: userID)
    }
    
    // Perform a full bidirectional sync
    func performFullSync(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer {
            isSyncing = false
            lastSyncTime = Date()
            UserDefaults.standard.set(lastSyncTime, forKey: "lastSyncTime")
        }
        
        // 1. First sync categories
        try await syncCategories(context: context, userID: userID)
        
        // 2. Then sync notes (which may reference categories)
        try await syncNotes(context: context, userID: userID)
    }
    
    // MARK: - Category Sync Functions
    
    private func syncCategories(context: NSManagedObjectContext, userID: UUID) async throws {
        print("Syncing categories")
        
        // 1. Fetch all local categories
        let localCategories = try fetchAllLocalCategories(context: context)
        
        // 2. Fetch all remote categories
        let remoteCategories = try await fetchAllRemoteCategories()
        
        // 3. Filter remote categories to only include those belonging to this user
        let userRemoteCategories = remoteCategories.filter { $0.owner_id == userID }
        
        // 4. Determine categories to upload, update, and download
        let localIDsSet = Set(localCategories.compactMap { $0.id })
        let remoteIDsSet = Set(userRemoteCategories.map { $0.id })
        
        let categoriesToUpload = localCategories.filter { category in
            guard let id = category.id else { return false }
            return !remoteIDsSet.contains(id)
        }
        
        let categoriesToUpdate = localCategories.filter { category in
            guard let id = category.id else { return false }
            return remoteIDsSet.contains(id)
        }
        
        let categoriesToDownload = userRemoteCategories.filter { category in
            return !localIDsSet.contains(category.id)
        }
        
        // 5. Perform the sync operations
        try await uploadCategories(categoriesToUpload, userID: userID)
        try await updateCategories(categoriesToUpdate, remoteCategories: userRemoteCategories, userID: userID)
        try await downloadCategories(categoriesToDownload, context: context)
        
        print("Category sync completed. Uploaded: \(categoriesToUpload.count), Updated: \(categoriesToUpdate.count), Downloaded: \(categoriesToDownload.count)")
    }
    
    private func uploadCategories(context: NSManagedObjectContext, userID: UUID) async throws {
        print("Starting uploadCategories")
        
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
        
        print("uploadCategories completed. Uploaded: \(categoriesToUpload.count), Updated: \(categoriesToUpdate.count)")
    }
    
    private func downloadCategoriesFromRemote(context: NSManagedObjectContext) async throws {
        print("Starting downloadCategoriesFromRemote")
        print("Starting downloadCategoriesFromRemote with context: \(context)")
        print("Context has persistent store coordinator: \(context.persistentStoreCoordinator != nil)")
        print("Persistent store coordinator has stores: \(context.persistentStoreCoordinator?.persistentStores.count ?? 0)")

        // Fetch remote categories
        let remoteCategories = try await fetchAllRemoteCategories()
        
        for category in remoteCategories {
            print("Remote category: id=\(category.id), name=\(category.name), owner_id=\(category.owner_id)")
        }
        
        // Download those categories
        try await downloadCategories(remoteCategories, context: context)
        
        print("downloadCategoriesFromRemote completed. Downloaded: \(remoteCategories.count)")
    }
    
    // MARK: - Note Sync Functions
    
    private func syncNotes(context: NSManagedObjectContext, userID: UUID) async throws {
        print("Syncing notes")
        
        // 1. Fetch all local notes
        let localNotes = try fetchAllLocalNotes(context: context)
        
        // 2. Fetch all remote notes
        let remoteNotes = try await fetchAllRemoteNotes()
        
        // 3. Filter remote notes to only include those belonging to this user
        let userRemoteNotes = remoteNotes.filter { $0.owner_id == userID }
        
        // 4. Determine notes to upload, update, and download
        let localIDsSet = Set(localNotes.compactMap { $0.id })
        let remoteIDsSet = Set(userRemoteNotes.map { $0.id })
        
        let notesToUpload = localNotes.filter { note in
            guard let id = note.id else { return false }
            return !remoteIDsSet.contains(id)
        }
        
        let notesToUpdate = localNotes.filter { note in
            guard let id = note.id else { return false }
            return remoteIDsSet.contains(id)
        }
        
        let notesToDownload = userRemoteNotes.filter { note in
            return !localIDsSet.contains(note.id)
        }
        
        // 5. Perform the sync operations
        try await uploadNotes(notesToUpload, userID: userID)
        try await updateNotes(notesToUpdate, remoteNotes: userRemoteNotes, userID: userID)
        try await downloadNotes(notesToDownload, context: context)
        
        print("Note sync completed. Uploaded: \(notesToUpload.count), Updated: \(notesToUpdate.count), Downloaded: \(notesToDownload.count)")
    }
    
    private func uploadNotes(context: NSManagedObjectContext, userID: UUID) async throws {
        print("Starting uploadNotes")
        
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
        
        print("uploadNotes completed. Uploaded: \(notesToUpload.count), Updated: \(notesToUpdate.count)")
    }
    
    private func downloadNotesFromRemote(context: NSManagedObjectContext) async throws {
        print("Starting downloadNotesFromRemote")
        
        // Fetch remote notes
        let remoteNotes = try await fetchAllRemoteNotes()
        
        // Download those notes
        try await downloadNotes(remoteNotes, context: context)
        
        print("downloadNotesFromRemote completed. Downloaded: \(remoteNotes.count)")
    }
    
    // MARK: - Helper Functions
    
    private func fetchAllLocalCategories(context: NSManagedObjectContext) throws -> [Category] {
        print("Fetching local categories")
        let request = NSFetchRequest<Category>(entityName: "Category")
        let categories = try context.fetch(request)
        print("Fetched \(categories.count) local categories")
        return categories
    }
    
    private func fetchAllRemoteCategories() async throws -> [SyncedCategory] {
        print("Fetching remote categories")
        let categories: [SyncedCategory] = try await client
            .from("synced_categories")
            .select()
            .execute()
            .value
        print("Fetched \(categories.count) remote categories")
        return categories
    }
    
    private func uploadCategories(_ categories: [Category], userID: UUID) async throws {
        print("Uploading \(categories.count) categories")
        
        // First, validate that all categories have valid UUIDs
        for (index, category) in categories.enumerated() {
            guard let id = category.id else {
                print("⚠️ Category at index \(index) is missing UUID - will be skipped")
                continue
            }
            
            print("Category to upload: id=\(id), name=\(category.name ?? "unnamed")")
        }
        
        // Filter out categories without UUIDs
        let validCategories = categories.filter { $0.id != nil }
        if validCategories.count < categories.count {
            print("⚠️ Skipping \(categories.count - validCategories.count) categories due to missing UUIDs")
        }
        
        for category in validCategories {
            do {
                let syncedCategory = category.toSyncedCategory(ownerID: userID)
                print("Uploading category: \(syncedCategory.id) - \(syncedCategory.name)")
                
                // Print category details for debugging
                print("  - UUID: \(syncedCategory.id)")
                print("  - Owner: \(syncedCategory.owner_id)")
                print("  - Name: \(syncedCategory.name)")
                print("  - Symbol: \(syncedCategory.symbol)")
                print("  - Color: \(syncedCategory.colorString)")
                print("  - Index: \(syncedCategory.index)")
                
                // Attempt the insert operation, but if it fails with a duplicate error, try update instead
                do {
                    let response = try await client
                    .from("synced_categories")
                    .insert(syncedCategory)
                    .execute()
                    
                    print("Insert response status: \(response.status)")
                print("Successfully uploaded category: \(syncedCategory.id)")
                } catch let error {
                    print("Insert failed with error: \(error.localizedDescription)")
                    print("Attempting update operation instead...")
                    
                    // Try update as fallback
                    try await client
                        .from("synced_categories")
                        .update(syncedCategory)
                        .eq("id", value: syncedCategory.id)
                        .execute()
                    
                    print("Successfully updated category: \(syncedCategory.id)")
                }
            } catch {
                print("Error processing category \(category.id?.uuidString ?? "unknown"): \(error.localizedDescription)")
                // Don't throw here - we want to try to upload as many categories as possible
                print("Continuing with next category...")
            }
        }
    }
    
    private func updateCategories(_ localCategories: [Category], remoteCategories: [SyncedCategory], userID: UUID) async throws {
        print("Updating \(localCategories.count) categories")
        for localCategory in localCategories {
            guard let id = localCategory.id else { continue }
            
            // Find matching remote category
            if let remoteCategory = remoteCategories.first(where: { $0.id == id }) {
                // For categories, we check if names, symbols, or colors have changed
                if localCategory.name != remoteCategory.name ||
                   localCategory.symbol != remoteCategory.symbol ||
                   localCategory.colorString != remoteCategory.colorString ||
                   Int(localCategory.index) != remoteCategory.index {
                    // Local category is different, update remote
                    let syncedCategory = localCategory.toSyncedCategory(ownerID: userID)
                    print("Updating category: \(syncedCategory.id) - \(syncedCategory.name)")
                    do {
                        try await client
                            .from("synced_categories")
                            .update(syncedCategory)
                            .eq("id", value: id)
                            .execute()
                        print("Successfully updated category: \(syncedCategory.id)")
                    } catch {
                        print("Error updating category \(id): \(error.localizedDescription)")
                        throw error
                    }
                }
            }
        }
    }
    
    private func downloadCategories(_ remoteCategories: [SyncedCategory], context: NSManagedObjectContext) async throws {
        print("Downloading \(remoteCategories.count) categories")
        
        // Check that the context has a valid persistent store coordinator with stores
        guard let coordinator = context.persistentStoreCoordinator else {
            print("ERROR: No persistent store coordinator found in context")
            throw SyncError.dataError("Core Data context has no persistent store coordinator")
        }
        
        guard coordinator.persistentStores.count > 0 else {
            print("ERROR: Persistent store coordinator has no stores")
            throw SyncError.dataError("Core Data has no persistent stores loaded")
        }
        
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
            
            do {
                let existingCategories = try context.fetch(request)
                
                if let existingCategory = existingCategories.first {
                    // Update existing category
                    print("Updating existing category: \(remoteCategory.id) - \(remoteCategory.name)")
                    existingCategory.name = remoteCategory.name
                    existingCategory.symbol = remoteCategory.symbol
                    existingCategory.colorString = remoteCategory.colorString
                    existingCategory.index = Int16(remoteCategory.index)
                } else {
                    // Create new local category
                    print("Creating new category: \(remoteCategory.id) - \(remoteCategory.name)")
                    let newCategory = Category(context: context)
                    newCategory.id = remoteCategory.id
                    newCategory.name = remoteCategory.name
                    newCategory.symbol = remoteCategory.symbol
                    newCategory.colorString = remoteCategory.colorString
                    newCategory.index = Int16(remoteCategory.index)
                }
            } catch {
                print("Error processing category \(remoteCategory.id): \(error.localizedDescription)")
                throw error
            }
        }
        
        // Save the context
        do {
            // Verify again before saving
            if context.persistentStoreCoordinator == nil || context.persistentStoreCoordinator?.persistentStores.count == 0 {
                print("ERROR: Persistent store not available before save")
                throw SyncError.dataError("Core Data has no persistent stores loaded")
            }
            
            if context.hasChanges {
            try context.save()
            print("Successfully saved downloaded categories to Core Data")
            } else {
                print("No changes to save to Core Data")
            }
        } catch {
            print("Error saving categories to Core Data: \(error.localizedDescription)")
            let nsError = error as NSError
            print("Domain: \(nsError.domain), Code: \(nsError.code)")
            print("User info: \(nsError.userInfo)")
            throw error
        }
    }
    
    private func fetchAllLocalNotes(context: NSManagedObjectContext) throws -> [Note] {
        print("Fetching local notes")
        let request = NSFetchRequest<Note>(entityName: "Note")
        let notes = try context.fetch(request)
        print("Fetched \(notes.count) local notes")
        return notes
    }
    
    private func fetchAllRemoteNotes() async throws -> [SyncedNote] {
        print("Fetching remote notes")
        let notes: [SyncedNote] = try await client
            .from("synced_notes")
            .select()
            .execute()
            .value
        print("Fetched \(notes.count) remote notes")
        return notes
    }
    
    private func uploadNotes(_ notes: [Note], userID: UUID) async throws {
        print("Uploading \(notes.count) notes")
        for note in notes {
            do {
                let syncedNote = note.toSyncedNote(ownerID: userID)
                print("Uploading note: \(syncedNote.id)")
                try await client
                    .from("synced_notes")
                    .insert(syncedNote)
                    .execute()
                print("Successfully uploaded note: \(syncedNote.id)")
            } catch {
                print("Error uploading note \(note.id?.uuidString ?? "unknown"): \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    private func updateNotes(_ localNotes: [Note], remoteNotes: [SyncedNote], userID: UUID) async throws {
        print("Updating \(localNotes.count) notes")
        for localNote in localNotes {
            guard let id = localNote.id else { continue }
            
            // Find matching remote note
            if let remoteNote = remoteNotes.first(where: { $0.id == id }) {
                // Always update remote from local since we can't reliably
                // determine which is newer without lastModified
                let syncedNote = localNote.toSyncedNote(ownerID: userID)
                print("Updating note: \(syncedNote.id)")
                do {
                    try await client
                        .from("synced_notes")
                        .update(syncedNote)
                        .eq("id", value: id)
                        .execute()
                    print("Successfully updated note: \(syncedNote.id)")
                } catch {
                    print("Error updating note \(id): \(error.localizedDescription)")
                    throw error
                }
            }
        }
    }
    
    private func downloadNotes(_ remoteNotes: [SyncedNote], context: NSManagedObjectContext) async throws {
        print("Downloading \(remoteNotes.count) notes")
        
        // Check that the context has a valid persistent store coordinator with stores
        guard let coordinator = context.persistentStoreCoordinator else {
            print("ERROR: No persistent store coordinator found in context")
            throw SyncError.dataError("Core Data context has no persistent store coordinator")
        }
        
        guard coordinator.persistentStores.count > 0 else {
            print("ERROR: Persistent store coordinator has no stores")
            throw SyncError.dataError("Core Data has no persistent stores loaded")
        }
        
        // Get the current user ID to ensure we only download our own notes
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        // Only process notes from the current user
        let userNotes = remoteNotes.filter { $0.owner_id == userID }
        print("Filtered to \(userNotes.count) notes belonging to current user")
        
        for remoteNote in userNotes {
            // Check if a note with this ID already exists locally
            let request = NSFetchRequest<Note>(entityName: "Note")
            request.predicate = NSPredicate(format: "id == %@", remoteNote.id as CVarArg)
            
            do {
                let existingNotes = try context.fetch(request)
                
                var noteToUpdate: Note
                
                if let existingNote = existingNotes.first {
                    // Compare timestamps to determine which is newer
                    let localTimestamp = existingNote.lastModified ?? Date.distantPast
                    let remoteTimestamp = remoteNote.last_modified ?? Date.distantPast
                    
                    if remoteTimestamp <= localTimestamp {
                        print("Local note \(remoteNote.id) is newer, skipping update")
                        // Local note is newer or same age, skip this note
                        continue
                    }
                    
                    // Remote note is newer, update local note
                    print("Updating existing note: \(remoteNote.id)")
                    noteToUpdate = existingNote
                } else {
                    // Create new local note
                    print("Creating new note: \(remoteNote.id)")
                    noteToUpdate = Note(context: context)
                    noteToUpdate.id = remoteNote.id
                }
                
                // Ensure we can convert the attributedTextData
                guard let attributedText = try? remoteNote.toAttributedString() else {
                    print("Failed to convert attributedTextData for note \(remoteNote.id)")
                    continue
                }
                
                // Update note properties
                noteToUpdate.attributedText = attributedText
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
                    
                    let categories = try context.fetch(categoryRequest)
                    if let category = categories.first {
                        noteToUpdate.category = category
                    } else {
                        print("Category \(categoryID) not found for note \(remoteNote.id)")
                    }
                }
            } catch {
                print("Error processing note \(remoteNote.id): \(error.localizedDescription)")
                // Continue with other notes instead of failing the entire batch
                continue
            }
        }
        
        // Save the context
        do {
            // Verify again before saving
            if context.persistentStoreCoordinator == nil || context.persistentStoreCoordinator?.persistentStores.count == 0 {
                print("ERROR: Persistent store not available before save")
                throw SyncError.dataError("Core Data has no persistent stores loaded")
            }
            
            if context.hasChanges {
            try context.save()
            print("Successfully saved downloaded notes to Core Data")
            } else {
                print("No changes to save to Core Data")
            }
        } catch {
            print("Error saving notes to Core Data: \(error.localizedDescription)")
            let nsError = error as NSError
            print("Domain: \(nsError.domain), Code: \(nsError.code)")
            print("User info: \(nsError.userInfo)")
            throw error
        }
    }
    
    enum SyncError: Error, LocalizedError {
        case notAuthenticated
        case networkError(String)
        case dataError(String)
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "You must be signed in to sync data"
            case .networkError(let message):
                return "Network error: \(message)"
            case .dataError(let message):
                return "Data error: \(message)"
            }
        }
    }
}
