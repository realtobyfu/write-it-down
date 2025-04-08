import SwiftUI
import CoreData
import RichTextKit
import PhotosUI
import CoreLocation
import MapKit
import UIKit

struct ContentView: View {

    // MARK: - Core Data & Environment
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var authVM: AuthViewModel

    // MARK: - FetchRequests
    @FetchRequest(
        entity: Note.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.index, ascending: true)]
    ) var notes: FetchedResults<Note>

    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>

    // MARK: - Local State
//    @State private var showingNoteEditor = false
    @State private var selectedNote: Note?
    @State private var showingAddNoteView = false
    @State private var showingAuthView = false
    @State private var showBubbles = false
    @State private var selectedCategory: Category?

    // For “Fold All”
    @State private var foldAll = false

    // For “Sort by Date” toggle
    @State private var sortByDateDesc = false

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Filtered + Sorted Notes
    var filteredNotes: [Note] {
        if let category = selectedCategory {
            // Filter by category
            return notes.filter { $0.category == category }
        } else {
            // No filter => show all
            return Array(notes)
        }
    }

    var displayedNotes: [Note] {
        // If user toggles date sort, use note.date
        // Otherwise, use note.index as the manual reorder
        if sortByDateDesc {
            // sort descending by date
            return filteredNotes.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        } else {
            // default to the "index" property for manual ordering
            return filteredNotes.sorted { $0.index < $1.index }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("Ideas")
                        .italic()
                        .font(.title)
                        .fontWeight(.medium)
                    Spacer()
                    Button(action: {
                        showingAuthView = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 24))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 15)

                // Category Filter + Fold/Sort Toggles
                CategoryFilterView(
                    selectedCategory: $selectedCategory,
                    categories: Array(categories),
                    foldAll: $foldAll,
                    sortByDateDesc: $sortByDateDesc
                )
                .font(.subheadline)
                .padding(.bottom, 5)

                // NOTES LIST
                List {
                    ForEach(displayedNotes) { note in
                        NoteView(
                            note: note,
                            foldAll: foldAll,
                            buttonTapped: {
                                selectedNote = note
//                                showingNoteEditor = true
                            }
                        )
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        Task {
                            await deleteNote(at: indexSet)
                        }
                    }
                    // Only allow reordering if no category & no date sort
                    .onMove(perform: moveNote)
                    .moveDisabled(selectedCategory != nil || sortByDateDesc)
                }
                .listStyle(PlainListStyle())
                .safeAreaInset(edge: .bottom) {
                    // Horizontal Bubble Menu
                    BubbleMenuView(
                        showBubbles: $showBubbles,
                        selectedCategory: $selectedCategory,
                        categories: Array(categories),
                        onCategorySelected: {
                            showingAddNoteView = true
                        }
                    )
                }

                Spacer()

                // PLUS Button & Nav Buttons
                ZStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showBubbles.toggle()
                            }
                        }) {
                            Image(systemName: showBubbles ? "minus.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 52))
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }

                    HStack {
                        NavigationLink(destination: FeedView(isAuthenticated: authVM.isAuthenticated)) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                                .padding(5)
                                .clipShape(Circle())
                        }
                        .padding(.leading, 50)

                        Spacer()

                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 50)
                    }
                }
            }
        }
        // Save context on background
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                saveContext()
            }
        }
        // Present Note Editor
        .sheet(item: $selectedNote, onDismiss: {
            selectedNote = nil
        }) { note in
//            if let note = selectedNote {
                NoteEditorView(
                    mode: .edit(note),
                    categories: Array(categories), context: context,
                    isAuthenticated: authVM.isAuthenticated,
                    onSave: { saveContext() }
                )
//            } else {
//                Text("No note selected")
//            }
        }
        // Present "Add Note" after picking category bubble
        .sheet(isPresented: $showingAddNoteView, onDismiss: {
            selectedCategory = nil
        }) {
            NoteEditorView(
                mode: .create(selectedCategory!),
                categories: Array(categories), context: context,
                isAuthenticated: authVM.isAuthenticated,
                onSave: { saveContext() }
            )
        }
        // Auth / Profile sheet
        .sheet(isPresented: $showingAuthView) {
            if authVM.isAuthenticated {
                UserView(authVM: authVM)
            } else {
                AuthenticationView(authVM: authVM)
            }
        }
    }

    // MARK: - Deletions & Reordering

    private func deleteNote(at offsets: IndexSet) async {
        for index in offsets {
            let noteToDelete = displayedNotes[index]
            if let noteID = noteToDelete.id {
                do {
                    let exists = await NoteRepository.shared.noteExistsInSupabase(noteID: noteID)
                    if exists {
                        try await NoteRepository.shared.deletePublicNote(noteID)
                    }
                } catch {
                    print("Error deleting note from Supabase: \(error)")
                }
            }
            context.delete(noteToDelete)
        }
        saveContext()
    }

    private func moveNote(from source: IndexSet, to destination: Int) {
        // Because we store user-defined ordering in note.index,
        // we re-map notes, reorder them, then update each note.index
        var reorderedNotes = Array(notes)  // the entire fetch, unsorted
        reorderedNotes.move(fromOffsets: source, toOffset: destination)

        // Set new indexes
        for (newIndex, note) in reorderedNotes.enumerated() {
            note.index = Int16(newIndex)
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}




// MARK: - CategoryFilterView
struct CategoryFilterView: View {
    @Binding var selectedCategory: Category?
    var categories: [Category]

    // For “Fold All” & “Sort by Date”
    @Binding var foldAll: Bool
    @Binding var sortByDateDesc: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack {
            // Title row
            HStack {
                Text("Categories")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()

                HStack(spacing: 16) {
                    // Expand/collapse categories
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }

                    // Fold All
                    Button(action: {
                        withAnimation {
                            foldAll.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(foldAll ? .red : ((colorScheme == .dark) ? .white : .orange))
                    }

                    // Sort by Date
                    Button(action: {
                        withAnimation {
                            sortByDateDesc.toggle()
                        }
                    }) {
                        Image(systemName: "calendar")
                            .foregroundColor(sortByDateDesc ? .red : ((colorScheme == .dark) ? .white : .orange))
                    }
                }
            }
            .padding(.horizontal)

            // Bubbles, if expanded
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // "All" button
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            Text("All")
                                .padding(8)
                                .background(selectedCategory == nil ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }

                        // Each category bubble
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedCategory == category ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.slide)
            }
        }
    }
}

//
//// MARK: - Checking if note is in DB
//@MainActor
//func checkExistInDB(note: Note) async -> Bool {
//    do {
//        let response: [SupabaseNote] = try await SupabaseManager.shared.client
//            .from("public_notes")
//            .select()
//            .eq("id", value: note.id)
//            .execute()
//            .value
//        return !response.isEmpty
//    } catch {
//        print("error: (\(error))")
//        return false
//    }
//}
