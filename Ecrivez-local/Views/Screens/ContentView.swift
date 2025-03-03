import SwiftUI
import CoreData
import RichTextKit
import PhotosUI
import CoreLocation
import MapKit
import UIKit

struct ContentView: View {

    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var authVM: AuthViewModel

    @FetchRequest(
        entity: Note.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.index, ascending: true)]
    ) var notes: FetchedResults<Note>

    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>

    @State private var showingNoteEditor = false
    @State private var selectedNote: Note?
    @State private var showingAddNoteView = false
    @State private var showingAuthView = false
    @State private var showBubbles = false
    @State private var selectedCategory: Category?

    @Environment(\.scenePhase) private var scenePhase

    var filteredNotes: [Note] {
        if let category = selectedCategory {
            return notes.filter { $0.category == category }
        } else {
            return Array(notes)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Ideas")
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


                CategoryFilterView(
                    selectedCategory: $selectedCategory,
                    categories: Array(categories)
                )
                .font(.subheadline)
                .padding(.bottom, 5)

                List {
                    ForEach(filteredNotes) { note in
                        NoteView(
                            note: note,
                            buttonTapped: {
                                selectedNote = note
                                showingNoteEditor = true
                            }
                        )
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { IndexSet in
                        Task {
                            await deleteNote(at: IndexSet)
                        }
                    }
                    .onMove(perform: moveNote)
                    .moveDisabled(selectedCategory != nil)
                }
                .safeAreaInset(edge: .bottom) {
                    BubbleMenuView(
                        showBubbles: $showBubbles,
                        selectedCategory: $selectedCategory,
                        categories: Array(categories),
                        onCategorySelected: {
                            showingAddNoteView = true
                        }
                    )
                }
                .listStyle(PlainListStyle())

                Spacer()

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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                saveContext()
            }
        }
        .sheet(isPresented: $showingNoteEditor, onDismiss: {
            selectedNote = nil
        }) {
            if let note = selectedNote {
                NoteEditorView(
                    mode: .edit(note),
                    categories: Array(categories),
                    isAuthenticated: authVM.isAuthenticated,
                    onSave: {
                        saveContext()
                    }
                )
            }
        }
        .sheet(isPresented: $showingAddNoteView, onDismiss: {
            selectedCategory = nil
        }) {
            if let selectedCategory = selectedCategory {
                NoteEditorView(
                    mode: .create(selectedCategory),
                    categories: Array(categories),
                    isAuthenticated: authVM.isAuthenticated,
                    onSave: {
                        saveContext()
                    }
                )
            }
        }
        .sheet(isPresented: $showingAuthView) {
            if authVM.isAuthenticated {
                UserView(authVM: authVM)
            } else {
                AuthenticationView(authVM: authVM)
            }
        }
    }

    private func deleteNote(at offsets: IndexSet) async {
        for index in offsets {
            let noteToDelete = filteredNotes[index]
            let existInDB = await checkExistInDB(note: noteToDelete)

            if existInDB {
                do {
                    _ = try await SupabaseManager.shared.client
                        .from("public_notes")
                        .delete()
                        .eq("id", value: noteToDelete.id)
                        .execute()
                } catch {
                    print("Error deleting note from Supabase: \(error)")
                }
            }

            context.delete(noteToDelete)
        }
        saveContext()
    }

    private func moveNote(from source: IndexSet, to destination: Int) {
        guard selectedCategory == nil else { return }

        var reorderedNotes = notes.map { $0 }
        reorderedNotes.move(fromOffsets: source, toOffset: destination)

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





// CategoryFilterView displays category bubbles for filtering notes
struct CategoryFilterView: View {
    @Binding var selectedCategory: Category?
    var categories: [Category]

    @State private var isExpanded: Bool = false // Default to collapsed

    var body: some View {
        VStack {
            // Toggle button to expand/collapse the view
            HStack {
                Text("Categories")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Display categories if expanded
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // "All" button to reset the filter
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            Text("All")
                                .padding(8)
                                .background(selectedCategory == nil ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        Spacer()
                        // Category bubbles
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 30, height: 30)
//                                    .overlay(
//                                        Image(systemName: category.symbol ?? "circle")
//                                            .foregroundColor(.white)
//                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedCategory == category ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.slide) // Smooth transition for expand/collapse
            }
        }
    }
}

@MainActor
func checkExistInDB (note: Note) async -> Bool {
    do {
        let response: [SupabaseNote] = try await SupabaseManager.shared.client
            .from("public_notes")
            .select()
            .eq("id", value: note.id)
            .execute()
            .value
        
        return !response.isEmpty
    } catch {
        print("error: (\(error))")
    }
    return false
}
