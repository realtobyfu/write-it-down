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
    // after doing this, we can use notes as a normal Swift array
    @FetchRequest(
        entity: Note.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.id, ascending: false)]
    ) var notes: FetchedResults<Note>
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>

    @State private var showingNoteEditor = false
    @State private var selectedNote: Note?
    @State private var deleteMode = false
    @State private var showingAddNoteView = false
    @State private var showBubbles = false
    @State private var selectedCategory: Category?

    @Environment(\.scenePhase) private var scenePhase // Observe the app’s lifecycle

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(notes) { note in
                        NoteView(
                            note: note,
                            selectedNote: $selectedNote,
                            showingNoteEditor: $showingNoteEditor
                        )
                    }
                    .onMove(perform: moveNote)
                    .onDelete(perform: deleteNote)
                }
                .padding(.bottom, showBubbles ? 100 : 0)
                .listStyle(PlainListStyle())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            deleteMode.toggle()
                        }) {
                            Text(deleteMode ? "Done" : "Edit")
                        }
                    }
                }
                .navigationTitle("Ideas")
                
                .sheet(isPresented: $showingNoteEditor, onDismiss: {
                    selectedNote = nil
                }) {
                    if let note = selectedNote {
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

                Spacer()

                ZStack {
                    // Horizontal Bar of Pop-up Bubbles
                    BubbleMenuView(
                        showBubbles: $showBubbles,
                        selectedCategory: $selectedCategory,
                        categories: Array(categories),
                        onCategorySelected: {
                            showingAddNoteView = true
                        }
                    )

                    // Plus Button
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
                        .frame(alignment: .center)
                        Spacer()
                    }
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
                        
                        NavigationLink(destination: SettingsView(categories: _categories)) {
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
    }
    
    private func deleteNote(at offsets: IndexSet) {
        for index in offsets {
            let noteToDelete = notes[index]
            context.delete(noteToDelete)
        }
        saveContext()
    }
    
    private func moveNote(from source: IndexSet, to destination: Int) {
        // Perform any reordering logic if needed (typically for display purposes)
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
