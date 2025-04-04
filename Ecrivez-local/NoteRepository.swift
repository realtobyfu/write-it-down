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
        // Convert NSAttributedString -> RTF base64
        let rtfData = try note.attributedText.data(
            from: NSRange(location: 0, length: note.attributedText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        let base64RTF = rtfData.base64EncodedString()
        
        let supaNote = SupabaseNote(
            id: note.id ?? UUID(),
            owner_id: ownerID,
            category_id: note.category?.id,
            content: note.attributedText.string,   // plain text
            rtf_content: base64RTF,               // full RTF
            date: note.date,
            locationName: note.placeName,
            locationLatitude: note.locationLatitude?.stringValue,
            locationLongitude: note.locationLongitude?.stringValue,
            colorString: note.category?.colorString ?? "",
            symbol: note.category?.symbol ?? "",
            isAnnonymous: note.isAnnonymous
        )
        return supaNote
    }
}
