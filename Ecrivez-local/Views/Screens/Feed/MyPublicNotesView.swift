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
    
    // Add this state variable for the selected note
    @State private var selectedLocalNote: Note?
    @State private var showingNoteEditor = false
    
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
                Task {
                    await loadMyPublicNotes()
                }
            }
            // Add sheet presentation for the selected note
            .sheet(isPresented: $showingNoteEditor) {
                if let note = selectedLocalNote {
                    NoteEditorView(
                        mode: .edit(note),
                        categories: fetchCategories(),
                        context: context,
                        isAuthenticated: authVM.isAuthenticated,
                        onSave: {
                            Task {
                                await loadMyPublicNotes()
                            }
                        }
                    )
                }
            }
        }
    }
    
    // Add this function to actually load and store the notes
    private func loadMyPublicNotes() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            myNotes = try await NoteRepository.shared.fetchMyPublicNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Subview
    @ViewBuilder
    private func RowView(supaNote: SupabaseNote) -> some View {
        // 1) Check if there's a matching local note in Core Data
        if let localNote = fetchLocalNote(with: supaNote.id) {
            // If the note is local, allow editing
            Button {
                selectedLocalNote = localNote
                showingNoteEditor = true
            } label: {
                PublicNoteRow(supaNote: supaNote)
                    .foregroundColor(.primary) // Make it look like a regular row
            }
        } else {
            // If no local note, just show a row that can be deleted from Supabase
            HStack {
                PublicNoteRow(supaNote: supaNote)
                Spacer()
                Button(role: .destructive) {
                    Task {
                        try await NoteRepository.shared.deletePublicNote(supaNote.id)
                        // Refresh the list after deletion
                        await loadMyPublicNotes()
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
}

// MARK: - Row Display
struct PublicNoteRow: View {
    let supaNote: SupabaseNote
    
    var body: some View {
        HStack {
            Text(supaNote.content.prefix(50)) // or a more advanced snippet
            Spacer()
        }
    }
}
