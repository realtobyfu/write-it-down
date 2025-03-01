//
//  MyPublicNotesView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/28/25.
//


import SwiftUI
import CoreData

struct MyPublicNotesView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var myNotes: [SupabaseNote] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading your public notes...")
                } else if let errorMessage {
                    Text("Error: \(errorMessage)")
                } else if myNotes.isEmpty {
                    Text("No public notes found in your account.")
                } else {
                    List {
                        ForEach(myNotes) { supaNote in
                            RowView(supaNote: supaNote)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Public Notes")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task { await loadMyPublicNotes() }
            }
        }
    }
    
    // MARK: - Subview
    @ViewBuilder
    private func RowView(supaNote: SupabaseNote) -> some View {
        // 1) Check if there's a matching local note in Core Data
        if let localNote = fetchLocalNote(with: supaNote.id) {
            // If the note is local, allow editing
                NavigationLink(destination: {
                    NoteEditorView(
                        mode: .edit(localNote),
                        categories: fetchCategories(), // Helper to pass categories
                        isAuthenticated: authVM.isAuthenticated,
                        onSave: { /* do any extra save logic if needed */ }
                    )
                }) {
                    PublicNoteRow(supaNote: supaNote)
                }
            } else {
            // If no local note, just show a row that can be deleted from Supabase
                HStack {
                    PublicNoteRow(supaNote: supaNote)
                    Spacer()
                    Button(role: .destructive) {
                        Task {
                            await deleteFromSupabase(supaNote.id)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
        }
    }
    
    // MARK: - Helpers
    
    private func fetchLocalNote(with id: UUID) -> Note? {
        // Quick fetch from Core Data
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching local note by ID: \(error)")
            return nil
        }
    }
    
    /// A small snippet for building an array of Category from your fetch request
    private func fetchCategories() -> [Category] {
        let request = NSFetchRequest<Category>(entityName: "Category")
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    private func loadMyPublicNotes() async {
        guard let userID = try? await SupabaseManager.shared.client.auth.user().id else {
            errorMessage = "No user session found."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let notes: [SupabaseNote] = try await SupabaseManager.shared.client
                .from("public_notes")
                .select()
                .eq("owner_id", value: userID) // Only the user's own notes
                .order("date", ascending: false) // or "id"
                .execute()
                .value
            
            myNotes = notes
        } catch {
            print("Error loading user's public notes: \(error)")
            errorMessage = "Failed to load your notes."
        }
    }
    
    private func deleteFromSupabase(_ noteID: UUID) async {
        do {
            try await SupabaseManager.shared.client
                .from("public_notes")
                .delete()
                .eq("id", value: noteID)
                .execute()
            
            // Remove from myNotes array
            if let idx = myNotes.firstIndex(where: { $0.id == noteID }) {
                myNotes.remove(at: idx)
            }
            print("Deleted from supabase successfully.")
            
        } catch {
            print("Error deleting note in supabase: \(error)")
            errorMessage = "Failed to delete note in Supabase."
        }
    }
}

// MARK: - Row Display
/// A small subview for a single row. E.g. you can do a minimal display or replicate `PublicNoteView`.
struct PublicNoteRow: View {
    let supaNote: SupabaseNote
    
    var body: some View {
        HStack {
            Text(supaNote.content.prefix(50)) // or a more advanced snippet
            Spacer()
        }
    }
}
