import SwiftUI
import CoreData
import RichTextKit
import PhotosUI
import CoreLocation
import MapKit
import UIKit

struct ContentView: View {
    
    // MARK: - CoreData
    @Environment(\.managedObjectContext) private var context
    
    // Fetching Notes and Categories from CoreData
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

    @Environment(\.scenePhase) private var scenePhase // Observe the app’s lifecycle

    // Filtered notes based on the selected category
    var filteredNotes: [Note] {
        if let category = selectedCategory {
            return notes.filter { $0.category == category }
        } else {
            return Array(notes)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Category selection view at the top
                CategoryFilterView(
                    selectedCategory: $selectedCategory,
                    categories: Array(categories)
                )

                List {
                    ForEach(filteredNotes) { note in
                        NoteView(
                            note: note,
                            selectedNote: $selectedNote,
                            showingNoteEditor: $showingNoteEditor
                        )
                    }
                    .onDelete(perform: deleteNote)
                    .onMove(perform: moveNote)
                    .moveDisabled(selectedCategory != nil) // Disable moving when a category is selected
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Ideas")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAuthView = true
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 24))
                        }
                    }
                }
                .sheet(isPresented: $showingNoteEditor, onDismiss: {
                    selectedNote = nil
                }) {
                    if let note = selectedNote {
                        ZStack {
                            NoteEditorView(
                                mode: .edit(note),
                                categories: Array(categories),
                                onSave: {
                                    saveContext()
                                }
                            )
                            .frame(maxHeight: UIScreen.main.bounds.height / 1.5)
                        }
                    }
                }

                Spacer()

                ZStack {
                    // Horizontal Bar of Pop-up Bubbles for adding notes
                    BubbleMenuView(
                        showBubbles: $showBubbles,
                        selectedCategory: $selectedCategory,
                        categories: Array(categories),
                        onCategorySelected: {
                            showingAddNoteView = true
                        }
                    )

                    // Plus Button to show/hide BubbleMenuView
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

                    // Additional Navigation Buttons
                    HStack {
                        NavigationLink(destination: FeedView()) {
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
                saveContext() // Save context when app goes to background
            }
        }
        .sheet(
            isPresented: $showingAddNoteView,
            content: {
                if let selectedCategory = selectedCategory {
                    NoteEditorView(
                        mode: .create(selectedCategory),
                        categories: Array(categories),
                        onSave: {
                            saveContext()
                        }
                    )
                }
            }
        )
        .sheet(isPresented: $showingAuthView) {
            AuthenticationView()
        }
    }
    
    private func deleteNote(at offsets: IndexSet) {
        for index in offsets {
            let noteToDelete = filteredNotes[index]
            context.delete(noteToDelete)
        }
        saveContext()
    }
    
    private func moveNote(from source: IndexSet, to destination: Int) {
        guard selectedCategory == nil else { return } // Prevent moving when a category is selected

        var reorderedNotes = notes.map { $0 }
        
        reorderedNotes.move(fromOffsets: source, toOffset: destination)
        
        for (newIndex, note) in reorderedNotes.enumerated() {
            note.index = Int16(newIndex)
        }
        
        saveContext()
    }
    
    // Helper function to save context
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
                                .padding(10)
                                .background(selectedCategory == nil ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(15)
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
