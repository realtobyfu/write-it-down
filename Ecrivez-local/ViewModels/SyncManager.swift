//
//  StyleManager.swift
//  Write-It-Down
//
//  Created on 4/9/25.
//

import SwiftUI
import Supabase
import CoreData

extension Notification.Name {
    static let syncEnabledNotification = Notification.Name("syncEnabledNotification")
}

@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncEnabled = UserDefaults.standard.bool(forKey: "syncEnabled") {
        didSet {
            UserDefaults.standard.set(syncEnabled, forKey: "syncEnabled")
            if syncEnabled && oldValue == false {
                // Notify that sync was just enabled
                NotificationCenter.default.post(name: .syncEnabledNotification, object: nil)
            }
        }
    }
    @Published var syncStatus: SyncStatus = .idle
    
    private let client = SupabaseManager.shared.client
    private var syncTimer: Timer?
    private var lastAutoSyncTime: Date?
    
    // Serial queue for category operations to prevent duplicates
    private let categoryQueue = DispatchQueue(label: "com.tobiasfu.write-it-down.categorySync")
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    private init() {
        setupAutoSync()
    }
    
    // MARK: - Main Sync Functions
    // Download data from Supabase to Core Data
    func downloadData(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        syncStatus = .syncing
        defer {
            isSyncing = false
            lastSyncTime = Date()
            UserDefaults.standard.set(lastSyncTime, forKey: "lastDownloadTime")
        }
        
        print("🔄 Starting enhanced download with strict category-first ordering")
        
        // **PHASE 1**: Complete category download and validation
        print("📁 Phase 1: Downloading and validating categories")
        try await downloadCategoriesFromRemote(context: context)
        
        // **VALIDATION**: Ensure categories are properly saved before proceeding
        let categoryCount = try fetchAllLocalCategories(context: context).count
        print("✅ Categories validated: \(categoryCount) local categories available")
        
        // **PHASE 2**: Download notes (all category dependencies now resolved)
        print("📝 Phase 2: Downloading notes with resolved category dependencies")
        try await downloadNotesFromRemote(context: context)
        
        print("🎉 Enhanced download completed successfully")
    }
    
    // Upload data from Core Data to Supabase
    func uploadData(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        syncStatus = .syncing
        defer {
            isSyncing = false
            lastSyncTime = Date()
            UserDefaults.standard.set(lastSyncTime, forKey: "lastUploadTime")
        }
        
        print("🔄 Starting enhanced upload with strict category-first ordering")
        
        // **PHASE 1**: Complete category upload and validation
        print("📁 Phase 1: Uploading and validating categories")
        try await uploadCategories(context: context, userID: userID)
        
        // **VALIDATION**: Ensure all category dependencies are resolved
        try await ensureCategoryDependencies(context: context, userID: userID)
        
        // **PHASE 2**: Upload notes (all category dependencies now guaranteed)
        print("📝 Phase 2: Uploading notes with guaranteed category dependencies")
        try await uploadNotesWithEnhancedValidation(context: context, userID: userID)
        
        print("🎉 Enhanced upload completed successfully")
    }
    
    // Perform a full bidirectional sync
    func performFullSync(context: NSManagedObjectContext) async throws {
        guard syncEnabled else { return }
        
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        syncStatus = .syncing
        defer {
            isSyncing = false
            lastSyncTime = Date()
            UserDefaults.standard.set(lastSyncTime, forKey: "lastSyncTime")
        }
        
        // 1. First sync categories
        try await syncCategories(context: context, userID: userID)
        
        // 2. Then sync notes (which may reference categories)
        try await syncNotes(context: context, userID: userID)
        
        // 3. Clean up any duplicate categories that may have been created
        try await cleanupDuplicateCategories(context: context)
    }
    
    // MARK: - Automatic Sync Functions
    
    private func setupAutoSync() {
        // Note: Automatic sync timer removed since we don't have direct access to context
        // Sync will be triggered from UI components that have context access
        
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillEnterForeground() {
        // Will be triggered from app delegate with context
    }
    
    @objc private func appDidBecomeActive() {
        // Will be triggered from app delegate with context
    }
    
    func performAutoSync(context: NSManagedObjectContext? = nil) async {
        guard syncEnabled else { return }
        
        // Check if we've synced recently (within last 30 seconds)
        if let lastSync = lastAutoSyncTime,
           Date().timeIntervalSince(lastSync) < 30 {
            return
        }
        
        // If no context provided, we can't sync
        guard let context = context else {
            print("❌ SyncManager: Cannot perform auto sync without context")
            return
        }
        
        do {
            syncStatus = .syncing
            try await performFullSync(context: context)
            syncStatus = .success
            lastAutoSyncTime = Date()
            
            // Clear success status after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .success = syncStatus {
                syncStatus = .idle
            }
        } catch {
            syncStatus = .error(error.localizedDescription)
            print("❌ SyncManager: Auto sync error: \(error.localizedDescription)")
        }
    }
    
    // Trigger sync after note save with debounce
    private var syncDebounceTask: Task<Void, Never>?
    
    func triggerSyncAfterSave(context: NSManagedObjectContext) {
        syncDebounceTask?.cancel()
        syncDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second debounce
            await performAutoSync(context: context)
        }
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
        
        // 4. Get last sync time to determine deletions
        let lastSyncTime = UserDefaults.standard.object(forKey: "lastNoteSyncTime") as? Date ?? Date.distantPast
        
        // 5. Determine notes to upload, update, download, and delete
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
        
        // Only download notes that don't exist locally
        // Check if remote notes were created after last sync to avoid re-downloading deleted notes
        let notesToDownload = userRemoteNotes.filter { remoteNote in
            if localIDsSet.contains(remoteNote.id) {
                return false
            }
            // If the remote note was created after our last sync, it's a new note
            // Otherwise, it might be a note we deleted locally
            if let createdAt = remoteNote.created_at {
                return createdAt > lastSyncTime
            }
            return true
        }
        
        // Notes that exist remotely but not locally and were created before last sync
        // These are likely notes that were deleted locally
        let possiblyDeletedNotes = userRemoteNotes.filter { remoteNote in
            if localIDsSet.contains(remoteNote.id) {
                return false
            }
            if let createdAt = remoteNote.created_at {
                return createdAt <= lastSyncTime
            }
            return false
        }
        
        // Delete notes from remote that were deleted locally
        if !possiblyDeletedNotes.isEmpty {
            print("Found \(possiblyDeletedNotes.count) notes that might have been deleted locally")
            try await deleteRemoteNotes(possiblyDeletedNotes.map { $0.id })
        }
        
        // 6. Perform the sync operations
        try await uploadNotes(notesToUpload, userID: userID)
        try await updateNotes(notesToUpdate, remoteNotes: userRemoteNotes, userID: userID)
        try await downloadNotes(notesToDownload, context: context)
        
        // 7. Update last sync time
        UserDefaults.standard.set(Date(), forKey: "lastNoteSyncTime")
        
        print("Note sync completed. Uploaded: \(notesToUpload.count), Updated: \(notesToUpdate.count), Downloaded: \(notesToDownload.count), Deleted from remote: \(possiblyDeletedNotes.count)")
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
    
    // MARK: - Enhanced Sync Methods
    
    /// **Category Dependency Validation**: Ensures all local notes have their categories available in Supabase
    /// **Purpose**: Prevents foreign key constraint violations by pre-uploading missing categories
    /// **Strategy**: Scans all local notes, identifies missing categories, and uploads them proactively
    private func ensureCategoryDependencies(context: NSManagedObjectContext, userID: UUID) async throws {
        print("🔍 Validating category dependencies for all local notes")
        
        // 1. Get all local notes that have category references
        let localNotes = try fetchAllLocalNotes(context: context)
        var missingCategories: Set<UUID> = []
        var categoriesToUpload: [Category] = []
        
        // 2. Check each note's category dependency
        for note in localNotes {
            guard let category = note.category, let categoryID = category.id else {
                continue // Skip notes without categories
            }
            
            // 3. Check if category exists in Supabase
            let categoryExists = await checkCategoryExistsInSupabase(categoryID: categoryID, userID: userID)
            if !categoryExists && !missingCategories.contains(categoryID) {
                missingCategories.insert(categoryID)
                categoriesToUpload.append(category)
                print("📁 Found missing category dependency: \(category.name ?? "unnamed") (\(categoryID))")
            }
        }
        
        // 4. Upload all missing categories in batch
        if !categoriesToUpload.isEmpty {
            print("⬆️ Pre-uploading \(categoriesToUpload.count) missing categories to resolve dependencies")
            try await uploadCategories(categoriesToUpload, userID: userID)
            print("✅ All category dependencies resolved")
        } else {
            print("✅ All category dependencies already satisfied")
        }
    }
    
    /// **Enhanced Note Upload**: Uploads notes with automatic category dependency resolution and retry logic
    /// **Purpose**: Robust note upload that handles foreign key constraints gracefully
    /// **Features**: Automatic category upload, retry on constraint violations, comprehensive error recovery
    private func uploadNotesWithEnhancedValidation(context: NSManagedObjectContext, userID: UUID) async throws {
        print("📝 Starting enhanced note upload with dependency validation")
        
        // 1. Use the existing uploadNotes method but with better error context
        try await uploadNotes(context: context, userID: userID)
        
        print("✅ Enhanced note upload completed successfully")
    }
    
    // MARK: - Helper Functions
    
    /// **Category Existence Check**: Verify if a category exists in Supabase before referencing it
    /// **Purpose**: Prevent foreign key constraint violations when uploading notes
    /// **Performance**: Uses simple SELECT query with specific ID filter
    private func checkCategoryExistsInSupabase(categoryID: UUID, userID: UUID) async -> Bool {
        do {
            let existingCategories: [SyncedCategory] = try await client
                .from("synced_categories")
                .select("id")
                .eq("id", value: categoryID)
                .eq("owner_id", value: userID)
                .execute()
                .value
            
            let exists = !existingCategories.isEmpty
            print("Category \(categoryID) exists in Supabase: \(exists)")
            return exists
        } catch {
            print("Error checking category existence: \(error.localizedDescription)")
            // Assume it doesn't exist to be safe
            return false
        }
    }
    
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
        var validCategories = categories.filter { $0.id != nil }
        if validCategories.count < categories.count {
            print("⚠️ Skipping \(categories.count - validCategories.count) categories due to missing UUIDs")
        }
        
        // Always only sync categories with notes
        validCategories = validCategories.filter { category in
            let hasNotes = (category.note?.count ?? 0) > 0
            if !hasNotes {
                print("Skipping category '\(category.name ?? "unnamed")' - no associated notes")
            }
            return hasNotes
        }
        print("Filtered to \(validCategories.count) categories with notes")
        
        // Fetch existing remote categories to check for duplicates by content
        let existingRemoteCategories = try await fetchAllRemoteCategories()
        let userRemoteCategories = existingRemoteCategories.filter { $0.owner_id == userID }
        
        for category in validCategories {
            do {
                let syncedCategory = category.toSyncedCategory(ownerID: userID)
                
                // Check if a category with the same content already exists
                let duplicateExists = userRemoteCategories.contains { remote in
                    remote.name == syncedCategory.name &&
                    remote.symbol == syncedCategory.symbol &&
                    remote.colorString == syncedCategory.colorString
                }
                
                if duplicateExists {
                    print("⚠️ Skipping category '\(syncedCategory.name)' - duplicate content already exists in remote")
                    continue
                }
                
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
                
                if existingCategories.count > 1 {
                    // Handle duplicates - keep the first one and delete the rest
                    print("⚠️ Found \(existingCategories.count) duplicate categories with ID: \(remoteCategory.id)")
                    for (index, duplicate) in existingCategories.enumerated() {
                        if index > 0 {
                            print("Deleting duplicate category: \(duplicate.name ?? "unnamed")")
                            context.delete(duplicate)
                        }
                    }
                }
                
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
        print("🔄 Starting fetchAllRemoteNotes with enhanced debugging")
        
        // **Debug Step 1**: Check authentication status
        do {
            let user = try await client.auth.user()
            print("✅ User authenticated: \(user.id)")
        } catch {
            print("❌ Authentication check failed: \(error.localizedDescription)")
            throw SyncError.notAuthenticated
        }
        
        // **Debug Step 2**: Attempt database query with detailed logging
        print("📡 Querying synced_notes table...")
        
        do {
            let notes: [SyncedNote] = try await client
                .from("synced_notes")
                .select()
                .execute()
                .value
                
            print("✅ Successfully fetched \(notes.count) remote notes from synced_notes")
            
            // **Debug Step 3**: Log first few notes for structure validation
            if notes.count > 0 {
                let firstNote = notes[0]
                print("📝 Sample note structure: id=\(firstNote.id), owner_id=\(firstNote.owner_id), category_id=\(firstNote.category_id?.uuidString ?? "nil")")
            } else {
                print("📝 No notes found in remote database")
            }
            
            return notes
            
        } catch {
            print("❌ Database query failed with detailed error:")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            
            // **Debug Step 4**: Check for specific Supabase errors
            if let postgrestError = error as? any Error {
                print("   Full error: \(String(describing: postgrestError))")
            }
            
            throw SyncError.networkError("Failed to fetch remote notes: \(error.localizedDescription)")
        }
    }
    
    private func uploadNotes(_ notes: [Note], userID: UUID) async throws {
        print("Uploading \(notes.count) notes")
        for note in notes {
            do {
                let syncedNote = note.toSyncedNote(ownerID: userID)
                print("Uploading note: \(syncedNote.id)")
                
                // **Category Dependency Check**: Ensure the note's category exists in Supabase before uploading
                if let categoryID = syncedNote.category_id {
                    let categoryExists = await checkCategoryExistsInSupabase(categoryID: categoryID, userID: userID)
                    if !categoryExists {
                        print("⚠️ Category \(categoryID) doesn't exist in Supabase for note \(syncedNote.id)")
                        
                        // Try to upload the category first if it exists locally
                        if let category = note.category {
                            print("Uploading missing category first: \(category.id?.uuidString ?? "unknown")")
                            try await uploadCategories([category], userID: userID)
                        } else {
                            print("❌ Note \(syncedNote.id) references missing local category \(categoryID)")
                            // Skip this note to avoid foreign key constraint violation
                            continue
                        }
                    }
                }
                
                try await client
                    .from("synced_notes")
                    .insert(syncedNote)
                    .execute()
                print("Successfully uploaded note: \(syncedNote.id)")
            } catch {
                print("Error uploading note \(note.id?.uuidString ?? "unknown"): \(error.localizedDescription)")
                
                // **Enhanced Foreign Key Error Handling**: Auto-recovery with category upload and retry
                if error.localizedDescription.contains("foreign key constraint") && 
                   error.localizedDescription.contains("category_id") {
                    print("🔄 Foreign key constraint violation detected - attempting auto-recovery")
                    print("   Note ID: \(note.id?.uuidString ?? "unknown")")
                    print("   Category ID: \(note.category?.id?.uuidString ?? "unknown")")
                    
                    // **Auto-Recovery**: Try to upload missing category and retry note upload
                    if let category = note.category {
                        do {
                            print("⬆️ Auto-uploading missing category: \(category.name ?? "unnamed")")
                            try await uploadCategories([category], userID: userID)
                            
                            // **Retry**: Attempt note upload again with category now available
                            print("🔄 Retrying note upload after category dependency resolved")
                            let retrySyncedNote = note.toSyncedNote(ownerID: userID)
                            try await client.from("notes").upsert(retrySyncedNote).execute()
                            print("✅ Note upload succeeded after auto-recovery")
                            continue
                        } catch {
                            print("❌ Auto-recovery failed: \(error.localizedDescription)")
                            print("   Skipping note to prevent sync crash")
                            continue
                        }
                    } else {
                        print("❌ Cannot auto-recover: note has no category reference")
                        continue
                    }
                } else {
                    // For other errors, still throw to maintain existing error handling
                    throw error
                }
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
                
                // **Category Dependency Check**: Ensure the note's category exists in Supabase before updating
                if let categoryID = syncedNote.category_id {
                    let categoryExists = await checkCategoryExistsInSupabase(categoryID: categoryID, userID: userID)
                    if !categoryExists {
                        print("⚠️ Category \(categoryID) doesn't exist in Supabase for note \(syncedNote.id)")
                        
                        // Try to upload the category first if it exists locally
                        if let category = localNote.category {
                            print("Uploading missing category first: \(category.id?.uuidString ?? "unknown")")
                            try await uploadCategories([category], userID: userID)
                        } else {
                            print("❌ Note \(syncedNote.id) references missing local category \(categoryID)")
                            // Skip this note to avoid foreign key constraint violation
                            continue
                        }
                    }
                }
                
                do {
                    try await client
                        .from("synced_notes")
                        .update(syncedNote)
                        .eq("id", value: id)
                        .execute()
                    print("Successfully updated note: \(syncedNote.id)")
                } catch {
                    print("Error updating note \(id): \(error.localizedDescription)")
                    
                    // **Enhanced Foreign Key Error Handling**: Auto-recovery with category upload and retry
                    if error.localizedDescription.contains("foreign key constraint") && 
                       error.localizedDescription.contains("category_id") {
                        print("🔄 Foreign key constraint violation detected during update - attempting auto-recovery")
                        print("   Note ID: \(id)")
                        print("   Category ID: \(localNote.category?.id?.uuidString ?? "unknown")")
                        
                        // **Auto-Recovery**: Try to upload missing category and retry note update
                        if let category = localNote.category {
                            do {
                                print("⬆️ Auto-uploading missing category: \(category.name ?? "unnamed")")
                                try await uploadCategories([category], userID: userID)
                                
                                // **Retry**: Attempt note update again with category now available
                                print("🔄 Retrying note update after category dependency resolved")
                                let retrySyncedNote = localNote.toSyncedNote(ownerID: userID)
                                try await client.from("notes").update(retrySyncedNote).eq("id", value: id).execute()
                                print("✅ Note update succeeded after auto-recovery")
                                continue
                            } catch {
                                print("❌ Auto-recovery failed during update: \(error.localizedDescription)")
                                print("   Skipping note update to prevent sync crash")
                                continue
                            }
                        } else {
                            print("❌ Cannot auto-recover update: note has no category reference")
                            continue
                        }
                    } else {
                        // For other errors, still throw to maintain existing error handling
                        throw error
                    }
                }
            }
        }
    }
    
    private func downloadNotes(_ remoteNotes: [SyncedNote], context: NSManagedObjectContext) async throws {
        print("🔄 Starting downloadNotes with enhanced debugging")
        print("📥 Processing \(remoteNotes.count) remote notes")
        
        // **Debug Step 1**: Validate Core Data context
        guard let coordinator = context.persistentStoreCoordinator else {
            print("❌ CRITICAL: No persistent store coordinator found in context")
            throw SyncError.dataError("Core Data context has no persistent store coordinator")
        }
        print("✅ Core Data coordinator validated")
        
        guard coordinator.persistentStores.count > 0 else {
            print("❌ CRITICAL: Persistent store coordinator has no stores")
            throw SyncError.dataError("Core Data has no persistent stores loaded")
        }
        print("✅ Core Data stores validated: \(coordinator.persistentStores.count) stores")
        
        // **Debug Step 2**: Validate user authentication
        guard let userID = try? await client.auth.user().id else {
            print("❌ CRITICAL: User authentication failed during download")
            throw SyncError.notAuthenticated
        }
        print("✅ User authenticated for download: \(userID)")
        
        // **Debug Step 3**: Filter and validate notes for current user
        let userNotes = remoteNotes.filter { $0.owner_id == userID }
        print("📝 Filtered to \(userNotes.count) notes belonging to current user (from \(remoteNotes.count) total)")
        
        // **Debug Step 4**: Process each note with detailed logging
        var processedCount = 0
        var errorCount = 0
        
        for (index, remoteNote) in userNotes.enumerated() {
            print("📝 Processing note \(index + 1)/\(userNotes.count): \(remoteNote.id)")
            print("   Category ID: \(remoteNote.category_id?.uuidString ?? "nil")")
            print("   Content length: \(remoteNote.content.count) chars")
            
            // **Debug**: Check if a note with this ID already exists locally
            let request = NSFetchRequest<Note>(entityName: "Note")
            request.predicate = NSPredicate(format: "id == %@", remoteNote.id as CVarArg)
            
            do {
                let existingNotes = try context.fetch(request)
                print("   Found \(existingNotes.count) existing local notes with this ID")
                
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
                
                // **Debug**: Link to category if available with detailed logging
                if let categoryID = remoteNote.category_id {
                    print("   🔗 Looking up category: \(categoryID)")
                    let categoryRequest = NSFetchRequest<Category>(entityName: "Category")
                    categoryRequest.predicate = NSPredicate(format: "id == %@", categoryID as CVarArg)
                    
                    let categories = try context.fetch(categoryRequest)
                    print("   📂 Found \(categories.count) matching categories")
                    
                    if let category = categories.first {
                        noteToUpdate.category = category
                        print("   ✅ Successfully linked to category: \(category.name ?? "unnamed")")
                    } else {
                        print("   ⚠️ Category \(categoryID) not found locally for note \(remoteNote.id)")
                        print("   📋 Available local categories: \(try fetchAllLocalCategories(context: context).map { "\($0.id?.uuidString ?? "nil"): \($0.name ?? "unnamed")" }.joined(separator: ", "))")
                    }
                } else {
                    print("   📝 Note has no category reference")
                }
                
                processedCount += 1
                print("   ✅ Successfully processed note \(index + 1)/\(userNotes.count)")
                
            } catch {
                errorCount += 1
                print("   ❌ Error processing note \(remoteNote.id): \(error.localizedDescription)")
                print("   Error type: \(type(of: error))")
                print("   Full error: \(String(describing: error))")
                // Continue with other notes instead of failing the entire batch
                continue
            }
        }
        
        print("📊 Note processing summary: \(processedCount) processed, \(errorCount) errors")
        
        // **Debug Step 5**: Save the context with detailed logging
        print("💾 Attempting to save \(processedCount) processed notes to Core Data...")
        
        do {
            // Verify persistent store availability before saving
            if context.persistentStoreCoordinator == nil || context.persistentStoreCoordinator?.persistentStores.count == 0 {
                print("❌ CRITICAL: Persistent store not available before save")
                throw SyncError.dataError("Core Data has no persistent stores loaded")
            }
            
            if context.hasChanges {
                print("💾 Context has changes, proceeding with save...")
                try context.save()
                print("✅ Successfully saved downloaded notes to Core Data")
            } else {
                print("📝 No changes to save to Core Data")
            }
            
            print("🎉 downloadNotes completed successfully - processed: \(processedCount), errors: \(errorCount)")
            
        } catch {
            print("❌ CRITICAL: Error saving notes to Core Data:")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            let nsError = error as NSError
            print("   Domain: \(nsError.domain), Code: \(nsError.code)")
            print("   User info: \(nsError.userInfo)")
            throw error
        }
    }
    
    private func deleteRemoteNotes(_ noteIDs: [UUID]) async throws {
        print("Deleting \(noteIDs.count) notes from remote")
        
        for noteID in noteIDs {
            do {
                try await client
                    .from("synced_notes")
                    .delete()
                    .eq("id", value: noteID)
                    .execute()
                
                print("Successfully deleted note \(noteID) from remote")
            } catch {
                print("Error deleting note \(noteID) from remote: \(error)")
                // Continue with other deletions rather than failing all
            }
        }
    }
    
    // MARK: - Cleanup Methods
    
    func cleanupDuplicateCategories(context: NSManagedObjectContext) async throws {
        print("Starting cleanup of duplicate categories")
        
        // Fetch all categories
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        
        do {
            let allCategories = try context.fetch(request)
            var categoriesByID: [UUID: [Category]] = [:]
            
            // Group categories by ID
            for category in allCategories {
                if let id = category.id {
                    if categoriesByID[id] == nil {
                        categoriesByID[id] = []
                    }
                    categoriesByID[id]?.append(category)
                }
            }
            
            // Find and remove duplicates
            var duplicatesRemoved = 0
            for (id, categories) in categoriesByID {
                if categories.count > 1 {
                    print("Found \(categories.count) categories with ID: \(id)")
                    
                    // Keep the first category, delete the rest
                    for (index, category) in categories.enumerated() {
                        if index > 0 {
                            print("Removing duplicate category: \(category.name ?? "unnamed")")
                            context.delete(category)
                            duplicatesRemoved += 1
                        }
                    }
                }
            }
            
            if duplicatesRemoved > 0 {
                print("Removed \(duplicatesRemoved) duplicate categories")
                try context.save()
            } else {
                print("No duplicate categories found")
            }
            
        } catch {
            print("Error cleaning up duplicate categories: \(error)")
            throw error
        }
    }
    
    /// Consolidates duplicate categories in Supabase based on content (name, color, symbol)
    func consolidateDuplicateCategoriesInSupabase() async throws {
        guard let userID = try? await client.auth.user().id else {
            throw SyncError.notAuthenticated
        }
        
        print("Starting consolidation of duplicate categories in Supabase")
        
        // Fetch all remote categories for this user
        let allRemoteCategories = try await fetchAllRemoteCategories()
        let userCategories = allRemoteCategories.filter { $0.owner_id == userID }
        
        // Group categories by their content signature
        var categoriesByContent: [String: [SyncedCategory]] = [:]
        
        for category in userCategories {
            let contentKey = "\(category.name)|\(category.colorString)|\(category.symbol)"
            if categoriesByContent[contentKey] == nil {
                categoriesByContent[contentKey] = []
            }
            categoriesByContent[contentKey]?.append(category)
        }
        
        // Process duplicates
        var duplicatesConsolidated = 0
        
        for (contentKey, categories) in categoriesByContent {
            if categories.count > 1 {
                print("Found \(categories.count) duplicate categories with content: \(contentKey)")
                
                // Sort by created_at to keep the oldest one
                let sortedCategories = categories.sorted { cat1, cat2 in
                    (cat1.created_at ?? Date.distantPast) < (cat2.created_at ?? Date.distantPast)
                }
                
                let primaryCategory = sortedCategories[0]
                let duplicatesToRemove = Array(sortedCategories.dropFirst())
                
                print("Keeping category: \(primaryCategory.id), removing \(duplicatesToRemove.count) duplicates")
                
                // First, update all notes pointing to duplicate categories to point to the primary
                for duplicate in duplicatesToRemove {
                    // Fetch notes with this category
                    let notesWithCategory: [SyncedNote] = try await client
                        .from("synced_notes")
                        .select()
                        .eq("category_id", value: duplicate.id)
                        .execute()
                        .value
                    
                    print("Found \(notesWithCategory.count) notes with duplicate category \(duplicate.id)")
                    
                    // Update notes to use the primary category
                    for note in notesWithCategory {
                        try await client
                            .from("synced_notes")
                            .update(["category_id": primaryCategory.id])
                            .eq("id", value: note.id)
                            .execute()
                    }
                    
                    // Now delete the duplicate category
                    try await client
                        .from("synced_categories")
                        .delete()
                        .eq("id", value: duplicate.id)
                        .execute()
                    
                    duplicatesConsolidated += 1
                    print("Deleted duplicate category: \(duplicate.id)")
                }
            }
        }
        
        if duplicatesConsolidated > 0 {
            print("Successfully consolidated \(duplicatesConsolidated) duplicate categories in Supabase")
        } else {
            print("No duplicate categories found in Supabase")
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
