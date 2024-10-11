import SwiftUI
import RichTextKit
import PhotosUI
import CoreLocation
import MapKit
import UIKit

struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var showingNoteEditor = false
    @State private var selectedNote: Note?
    @State private var deleteMode = false
    @State private var showingAddNoteView = false
    @State private var showBubbles = false
    @State private var selectedCategory: Category?
    
    @State private var categories: [Category] = [
        Category(symbol: "book", colorName: "green", name: "Book"),
        Category(symbol: "fork.knife", colorName: "blue", name: "Cooking"),
        Category(symbol: "sun.min", colorName: "yellow", name: "Day"),
        Category(symbol: "movieclapper", colorName: "pink", name: "Movie"),
        Category(symbol: "message.badge.filled.fill", colorName: "brown", name: "Message"),
        Category(symbol: "list.bullet", colorName: "gray", name: "List")
    ]

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(notes) { note in
                        NoteView(
                            note: note,
                            selectedNote: $selectedNote,
                            showingNoteEditor: $showingNoteEditor,
                            deleteMode: $deleteMode,
                            onDelete: {
                                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                                    notes.remove(at: index)
                                }
                            }
                        )
                    }
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
                    // Update the notes array before clearing selectedNote
                    if let updatedNote = selectedNote {
                        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
                            notes[index] = updatedNote
                        }
                    }
                    selectedNote = nil
                }) {
                    if let note = selectedNote {
                        NoteEditorView(
                            mode: .edit(note),
                            categories: categories,
                            onSave: { updatedNote in
                            selectedNote = updatedNote
                        })
                        .frame(maxHeight: UIScreen.main.bounds.height / 1.5)
                    }
                }

                Spacer()

                ZStack {
                    // Horizontal Bar of Pop-up Bubbles
                    BubbleMenuView(
                        showBubbles: $showBubbles,
                        selectedCategory: $selectedCategory,
                        categories: categories,
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
                        
                        NavigationLink(destination: SettingsView(categories: $categories)) {
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
        .sheet(
            isPresented: $showingAddNoteView,
            content: {
                if let selectedCategory = selectedCategory {
                    NoteEditorView(
                        mode: .create(selectedCategory),
                        categories: categories,
                        onSave: { newNote in
                    notes.append(newNote)
                })
            }
        })
    }
}

