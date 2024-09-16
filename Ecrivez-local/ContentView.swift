import SwiftUI
import PhotosUI
import CoreLocation
import MapKit
import UIKit

struct Category: Hashable, Codable {
    var symbol: String
    var colorName: String

    var color: Color {
        switch colorName {
        case "green":
            return .green
        case "blue":
            return .blue
        case "yellow":
            return .yellow
        case "pink":
            return .pink
        case "brown":
            return .brown
        case "gray":
            return .gray
        default:
            return .white
        }
    }
}

struct Note: Identifiable, Codable {
    

    var id = UUID()
    var attributedTextData: Data // Store the attributed text as Data
    var images: [UIImage] = []
    var category: Category
    var date: Date? = nil
    var location: CLLocation? = nil

    var attributedText: NSAttributedString {
        get {
            do {
                return try NSAttributedString(data: attributedTextData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            } catch {
                print("Error decoding attributedTextData: \(error)")
                return NSAttributedString(string: "")
            }
        }
        set {
            do {
                attributedTextData = try newValue.data(from: NSRange(location: 0, length: newValue.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            } catch {
                print("Error encoding attributedText: \(error)")
                attributedTextData = Data()
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, attributedTextData, imagesData, category, date, locationData
    }

    // Encode images as Data
    var imagesData: [Data] {
        get {
            images.compactMap { $0.jpegData(compressionQuality: 1.0) }
        }
        set {
            images = newValue.compactMap { UIImage(data: $0) }
        }
    }

    // Location encoding
    var locationData: [String: Double]? {
        get {
            guard let location = location else { return nil }
            return ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
        }
    }

    // Custom encoding and decoding methods
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(attributedTextData, forKey: .attributedTextData)
        try container.encode(imagesData, forKey: .imagesData)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(date, forKey: .date)
        if let locationData = locationData {
            try container.encode(locationData, forKey: .locationData)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        attributedTextData = try container.decode(Data.self, forKey: .attributedTextData)
        let imageDatas = try container.decode([Data].self, forKey: .imagesData)
        images = imageDatas.compactMap { UIImage(data: $0) }
        category = try container.decode(Category.self, forKey: .category)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        if let locationDict = try container.decodeIfPresent([String: Double].self, forKey: .locationData),
           let latitude = locationDict["latitude"],
           let longitude = locationDict["longitude"] {
            location = CLLocation(latitude: latitude, longitude: longitude)
        } else {
            location = nil
        }
    }

    // Custom initializer
    init(id: UUID = UUID(), attributedText: NSAttributedString, images: [UIImage] = [], category: Category, date: Date? = nil, location: CLLocation? = nil) {
        self.id = id
        self.images = images
        self.category = category
        self.date = date
        self.location = location
        do {
            self.attributedTextData = try attributedText.data(from: NSRange(location: 0, length: attributedText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        } catch {
            print("Error encoding attributedText: \(error)")
            self.attributedTextData = Data()
        }
    }
}


struct AttributedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.textColor = UIColor.white

    }
}


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
                        NavigationLink(destination: SettingsView()) {
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

