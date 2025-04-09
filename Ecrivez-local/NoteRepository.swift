//
//  NoteRepository.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 3/26/25.
//

import Foundation
import Supabase
import CoreData

/// A service layer that handles all Supabase logic related to notes.
@MainActor
class NoteRepository {
    
    static let shared = NoteRepository()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    /// Checks if a given note ID currently exists in the `public_notes` table.
    func noteExistsInSupabase(noteID: UUID) async -> Bool {
        do {
            let response: [SupabaseNote] = try await client
                .from("public_notes")
                .select()
                .eq("id", value: noteID)
                .execute()
                .value
            return !response.isEmpty
        } catch {
            print("Error checking note existence in DB: \(error)")
            return false
        }
    }
    
    /// Upserts (insert or update) a note in Supabase.
    /// - Note: If the note does not exist yet, this inserts it.
    /// - If it does, we update.
    func upsertPublicNote(_ note: Note, ownerID: UUID) async throws {
        // Convert the local Note to a SupabaseNote
        let supaNote = try convertToSupabaseNote(note: note, ownerID: ownerID)
        
        let exists = await noteExistsInSupabase(noteID: supaNote.id)
        if exists {
            // Update existing
            try await client
                .from("public_notes")
                .update(supaNote)
                .eq("id", value: supaNote.id)
                .execute()
            print("Updated note in supabase, id: \(supaNote.id)")
        } else {
            // Insert new
            try await client
                .from("public_notes")
                .insert(supaNote)
                .execute()
            print("Inserted note in supabase, id: \(supaNote.id)")
        }
    }
    
    /// Deletes a note from `public_notes` table by its `id`.
    func deletePublicNote(_ noteID: UUID) async throws {
        try await client
            .from("public_notes")
            .delete()
            .eq("id", value: noteID)
            .execute()
        print("Deleted note from supabase, id: \(noteID)")
    }
    
    /// Fetch all public notes in descending order (example).
    func fetchAllPublicNotes() async throws -> [SupabaseNote] {
        try await client
            .from("public_notes")
            .select("id, owner_id, category_id, content, date, locationLongitude, locationLatitude, colorString, symbol, isAnnonymous, profiles (username)")
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    /// Fetch only notes belonging to a given user (owner).
    func fetchMyPublicNotes() async throws -> [SupabaseNote] {
        
        let ownerID = try? await SupabaseManager.shared.client.auth.user().id
        
        return try await client
            .from("public_notes")
            .select()
            .eq("owner_id", value: ownerID)
            .order("date", ascending: false)
            .execute()
            .value
    }
    
    // MARK: - Helpers
    
    /// Converts a local `Note` (Core Data) into a `SupabaseNote` for uploading.
    private func convertToSupabaseNote(note: Note, ownerID: UUID) throws -> SupabaseNote {
        // Get archived data using RichTextKit
        let archivedData = try note.attributedText.richTextData(for: .archivedData)
        let base64Archived = archivedData.base64EncodedString()
        
        // You can optionally keep rtf_content for backward compatibility
        // or set it to nil if you're fully migrating to archived_content
        let rtfData = try note.attributedText.richTextData(for: .rtf)
        let base64RTF = rtfData.base64EncodedString()
        
        let supaNote = SupabaseNote(
            id: note.id ?? UUID(),
            owner_id: ownerID,
            category_id: note.category?.id,
            content: note.attributedText.string,   // plain text
            rtf_content: base64RTF,                // keep for backward compatibility
            archived_content: base64Archived,      // new archived data
            date: note.date,
            locationName: note.landmark,
            locationLocality: note.locality,
            locationLatitude: note.locationLatitude?.stringValue,
            locationLongitude: note.locationLongitude?.stringValue,
            colorString: note.category?.colorString ?? "",
            symbol: note.category?.symbol ?? "",
            isAnnonymous: note.isAnnonymous
        )
        return supaNote
    }
}

// Add these methods to your existing NoteRepository.swift
@MainActor
extension NoteRepository {
    // MARK: - Likes Methods
    
    /// Fetch the count of likes for a specific note
    func fetchLikeCount(noteID: UUID) async throws -> Int {
        let response: [LikeModel] = try await client
            .from("note_likes")
            .select()
            .eq("note_id", value: noteID)
            .execute()
            .value
        
        return response.count
    }
    
    /// Check if the current user has liked a specific note
    func checkUserLikedNote(noteID: UUID) async -> Bool {
        guard let currentUserID = try? await client.auth.user().id else {
            return false
        }
        
        do {
            let response: [LikeModel] = try await client
                .from("note_likes")
                .select()
                .eq("note_id", value: noteID)
                .eq("user_id", value: currentUserID)
                .execute()
                .value
            
            return !response.isEmpty
        } catch {
            print("Error checking if user liked note: \(error)")
            return false
        }
    }
    
    /// Toggle a like for the current user on a specific note
    func toggleLike(noteID: UUID) async throws {
        guard let currentUserID = try? await client.auth.user().id else {
            throw NSError(domain: "NoteRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Check if the user already liked this note
        let hasLiked = await checkUserLikedNote(noteID: noteID)
        
        if hasLiked {
            // Unlike: Delete the existing like
            try await client
                .from("note_likes")
                .delete()
                .eq("note_id", value: noteID)
                .eq("user_id", value: currentUserID)
                .execute()
        } else {
            // Like: Insert a new like
            let like = ["note_id": noteID, "user_id": currentUserID]
            try await client
                .from("note_likes")
                .insert(like)
                .execute()
        }
    }
    
    // MARK: - Comments Methods
    
    /// Fetch comments for a specific note
    func fetchComments(noteID: UUID) async throws -> [CommentModel] {
        let comments: [CommentModel] = try await client
            .from("note_comments")
            .select("*, profiles(username, display_name, profile_photo_url)")
            .eq("note_id", value: noteID)
            .order("created_at")
            .execute()
            .value
        
        return comments
    }
    
    /// Add a comment to a note
    func addComment(noteID: UUID, content: String) async throws {
        guard let currentUserID = try? await client.auth.user().id else {
            throw NSError(domain: "NoteRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Create a properly structured comment object that conforms to Encodable
        struct NewComment: Encodable {
            let note_id: UUID
            let user_id: UUID
            let content: String
        }
        
        let comment = NewComment(
            note_id: noteID,
            user_id: currentUserID,
            content: content
        )
        
        try await client
            .from("note_comments")
            .insert(comment)
            .execute()
    }
    
    /// Update a comment
    func updateComment(commentID: UUID, newContent: String) async throws {
        try await client
            .from("note_comments")
            .update(["content": newContent, "updated_at": "now()"])
            .eq("id", value: commentID)
            .execute()
    }
    
    /// Delete a comment
    func deleteComment(commentID: UUID) async throws {
        try await client
            .from("note_comments")
            .delete()
            .eq("id", value: commentID)
            .execute()
    }
}
