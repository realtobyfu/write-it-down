import SwiftUI
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

    let categories: [Category] = [
        Category(symbol: "book", colorName: "green"),
        Category(symbol: "fork.knife", colorName: "blue"),
        Category(symbol: "sun.min", colorName: "yellow"),
        Category(symbol: "movieclapper", colorName: "pink"),
        Category(symbol: "clapperboard", colorName: "brown"),
        Category(symbol: "paperplane", colorName: "gray")
    ]

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(notes) { note in
                        VStack {
                            HStack {
                                // Image Scrolling
                                if !note.images.isEmpty {
                                    ScrollView(.horizontal) {
                                        HStack {
                                            ForEach(note.images, id: \.self) { image in
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading) {
                                    // Category Symbol on top of the text
                                    Image(systemName: note.category.symbol)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.bottom, 10)

                                    // Construct NSAttributedString with font and color
                                    let attributedText = NSAttributedString(
                                        string: note.attributedText.string, // Extract string from the note's attributed text
                                        attributes: [
                                            .font: UIFont.systemFont(ofSize: 18), // Set the font size to 24
                                            .foregroundColor: UIColor.white // Set text color to white
                                        ]
                                    )

                                    // Display the attributed text using AttributedTextView
                                    AttributedTextView(attributedText: attributedText)
                                        .onTapGesture {
                                            selectedNote = note
                                            showingNoteEditor = true
                                        }
                                        .foregroundColor(.white) // Ensure text is white if applicable
                                }
                                Spacer()
                                
                                if deleteMode {
                                    Button(action: {
                                        if let index = notes.firstIndex(where: { $0.id == note.id }) {
                                            notes.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(note.category.color) // Apply the note color to the background
                        .cornerRadius(20)
                        .padding(.vertical, 2)
                        .listRowSeparator(.hidden)
                        .foregroundColor(.white)
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
                        NoteEditorView(note: note, onSave: { updatedNote in
                            selectedNote = updatedNote
                        })
                        .frame(maxHeight: UIScreen.main.bounds.height / 1.5)
                    }
                }

                Spacer()

                ZStack {
                    // Horizontal Bar of Pop-up Bubbles
                    if showBubbles {
                        HStack(spacing: 20) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                    showingAddNoteView = true
                                    showBubbles = false
                                }) {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 45, height: 45)
                                        .overlay(
                                            Image(systemName: category.symbol)
                                                .foregroundColor(.white)
                                                .font(.headline)
                                        )
                                }
                            }
                        }
                        .offset(y: -100)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.5))
                    }

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
        .sheet(isPresented: $showingAddNoteView, content: {
            if let selectedCategory = selectedCategory {
                NoteEditorView(category: selectedCategory, onSave: { newNote in
                    notes.append(newNote)
                })
            }
        })
    }
}

