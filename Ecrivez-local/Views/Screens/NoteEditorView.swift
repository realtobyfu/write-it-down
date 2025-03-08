import SwiftUI

import CoreLocation
import RichTextKit

struct NoteEditorView: View {
    let categories: [Category]
    
    @State private var selectedDate: Date?
    @State private var attributedText: NSAttributedString

    // Make location optional
    @State private var location: CLLocationCoordinate2D?
    @State private var weather: String
    @State private var category: Category
    @State var isPublic: Bool = false
    @State var isAnnonymous: Bool = false
    
    // should not be "var" because inside a view,
    // you won't be able to change it meaningfully inside a view
    let note: Note?
    let onSave: () -> Void
    let isAuthenticated: Bool
    
    @Environment(\.colorScheme) var colorScheme

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var context  // Core Data context

    @State private var tapped: Bool = false
    @State private var showingImagePicker = false
    @State private var showingWeatherPicker = false
    @State private var showingLocationPicker = false  // State to control the presentation of LocationPickerView
    @State private var locationName: String?
    @FocusState private var isTextEditorFocused: Bool

    // RichTextKit context
    @StateObject private var contextRT = RichTextContext()  // Renamed to avoid conflict with Core Data context
    
    enum Mode {
        case edit(Note)
        case create(Category)
    }

    init(
        mode: Mode,
        categories: [Category],
        isAuthenticated: Bool,
        onSave: @escaping () -> Void
    ) {
        
        switch mode {
        case .edit(let note):
            self.init(
                isAuthenticated : isAuthenticated,
                note: note,
                categories: categories,
                category: note.category!,
                onSave: onSave
            )
        case .create(let category):
            self.init(
                isAuthenticated : isAuthenticated,
                note: nil,
                categories: categories,
                category: category,
                onSave: onSave
            )
        }
    }

    private init(
        isAuthenticated : Bool,
        note: Note?,
        categories: [Category],
        category: Category,
        onSave: @escaping () -> Void
    ) {
        
        self.note = note
        self.onSave = onSave
        self.categories = categories
        self.isAuthenticated = isAuthenticated

        _attributedText = State(initialValue: note?.attributedText ?? NSAttributedString())
        _location = State(initialValue: note?.location?.coordinate)  // Make location optional
        _weather = State(initialValue: "")  // Weather can be fetched or updated
        _tapped = State(initialValue: note != nil)
        _category = State(initialValue: category)
        _selectedDate = State(initialValue: note?.date)
        _isPublic = State(initialValue: note?.isPublic ?? false)
        _locationName  = State(initialValue: note?.placeName)
    }

    var body: some View {
        NavigationStack {
            VStack {

                #if os(macOS)
                RichTextFormat.Toolbar(context: contextRT)
                #endif

                // Category Selection
                categorySelectionView

                RichTextEditor(text: $attributedText, context: contextRT)
                    .padding(8)
//                    .background(Color.background)
                    .foregroundStyle(Color.background)
                    .focused($isTextEditorFocused)

                #if os(iOS)
                RichTextKeyboardToolbar(
                    context: contextRT,
                    leadingButtons: { $0 },
                    trailingButtons: { $0 },
                    formatSheet: { $0 }
                )
                .richTextKeyboardToolbarConfig(
                    .init(
                        leadingActions: [ .undo, .redo ],           // no .textColor
                        trailingActions: [ ]          // no .highlightColor
                    )
                )

                #endif
                
                
                if isAuthenticated {
                    if isPublic {
                        Toggle("Annonymous Post?", isOn: $isAnnonymous)
                            .padding(.vertical, 0)
                    }

                    Toggle("Make Public", isOn: $isPublic)
                        .padding(.vertical, 8)
                }
                

                // Location Picker View
                HStack {
                    if let location = location {
                        // Display the location bar if location is selected
                        LocationSelectionBar(location: location, placeName: locationName!)
                            .onTapGesture {
                                showingLocationPicker.toggle()
                            }
                    } else {
                        // Show a button to select location if none is selected
                        Button(action: {
                            showingLocationPicker.toggle()
                        }) {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.purple)
                                Text("Select Location")
                            }
                        }
                    }
                    Spacer()
                    // Displaying selected date or date picker
                    DateView(selectedDate: $selectedDate)
                        .padding(.leading, 5)

                    if !weather.isEmpty {
                        WeatherBar(weather: weather)
                            .padding(.leading, 5)
                            .padding(.bottom, 25)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                }
            }
            
            // check if the note is in the already, if so mark it as public
            //
//            .task {
//                do {
//                    let response = SupabaseManager.shared.client
//                       .from("public_notes")
//                        .select()
//                        .eq("note", value: note?.id)
//                        .single()
//                    
//                    if response {}
//                } catch {
//                    print("error")
//                }
//            }
            .onAppear {
                // Overwrite text color for entire string
                let mutable = NSMutableAttributedString(attributedString: attributedText)
                let entireRange = NSRange(location: 0, length: mutable.length)

                // 1) Remove any existing foreground color
                mutable.removeAttribute(.foregroundColor, range: entireRange)

                // 2) Add the color we want
                let newColor: UIColor = (colorScheme == .dark) ? .white : .black
                mutable.addAttribute(.foregroundColor, value: newColor, range: entireRange)

                // 3) Assign back
                attributedText = mutable

                print("Updated note:", attributedText) // Just to confirm
            }

            .padding([.leading, .trailing])
            .navigationBarTitle("Edit Note", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                saveNote()
            })
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button(action: {
                        showingWeatherPicker.toggle()
                    }) {
                        Image(systemName: "cloud.drizzle")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                    }

                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                            .padding(5)
                    }
                }
            }
            .sheet(isPresented: $showingWeatherPicker) {
                WeatherPicker(weather: $weather)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingLocationPicker) {
                // pass $location AND $locationName
                LocationPickerView(location: $location,
                                   locationName: $locationName)
            }
        }
    }

    private var categorySelectionView: some View {
        HStack(spacing: 17) {
            Spacer()

            Circle()
                .fill(category.color)
                .frame(width: 45, height: 45)
                .overlay(
                    Image(systemName: category.symbol!)
                        .foregroundColor(.white)
                        .font(.title2)
                )

            Spacer()

            if categories.count > 6 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 17) {
                        ForEach(categories.sorted(by: {$0.index < $1.index }).filter { $0.name != self.category.name }, id: \.self) { categoryItem in
                            Button(action: {
                                self.category = categoryItem
                            }) {
                                Circle()
                                    .fill(categoryItem.color)
                                    .frame(width: 35, height: 35)
                                    .overlay(
                                        Image(systemName: categoryItem.symbol!)
                                            .foregroundColor(.white)
                                            .font(.body)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 55) // Adjust if needed
            } else {
                // If 6 or fewer, just show them inline as before
                ForEach(categories.sorted(by: {$0.index < $1.index }).filter { $0.name != self.category.name }, id: \.self) { categoryItem in
                    Button(action: {
                        self.category = categoryItem
                    }) {
                        Circle()
                            .fill(categoryItem.color)
                            .frame(width: 35, height: 35)
                            .overlay(
                                Image(systemName: categoryItem.symbol!)
                                    .foregroundColor(.white)
                                    .font(.body)
                            )
                    }
                }
            }


//            Spacer()
        }
        .padding(.vertical, 5)
    }

    private func saveNote() {
        if attributedText.string.isEmpty { return }
        
        if let existing = note {
            // update
            existing.attributedText = attributedText
            existing.category       = category
            existing.date          = selectedDate
            existing.isPublic      = isPublic
            existing.isAnnonymous  = isAnnonymous
            existing.location      = location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            existing.placeName     = locationName ?? ""

            if existing.isPublic, isAuthenticated {
                Task { await updateSupabase(note: existing) }
            }
        } else {
            // create
            let newNote = Note(context: context)
            newNote.id = UUID()
            newNote.attributedText = attributedText
            newNote.category       = category
            newNote.date          = selectedDate
            newNote.isAnnonymous  = isAnnonymous
            newNote.location      = location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            newNote.placeName     = locationName ?? ""
            
            if newNote.isPublic, isAuthenticated {
                Task { await updateSupabase(note: newNote) }
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save note: \(error)")
        }
        presentationMode.wrappedValue.dismiss()
        onSave()
    }
}

@MainActor
func updateSupabase(note: Note) async {
    
    do {
        let user = try await SupabaseManager.shared.client.auth.user()
        
        print("ID of the user: \(user.id)")
        // 1) Convert local RichTextKit to RTF
        let rtfData = try note.attributedText.data(
            from: NSRange(location: 0, length: note.attributedText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        let base64RTF = rtfData.base64EncodedString()

        
        let existInDB = await checkExistInDB(note: note)
//        if !note.isPublic {
//            let _ = try await SupabaseManager.shared.client
//                .from("public_notes")
//                .delete()
//                .eq("id", value: note.id)
//                .execute()
//            
//            print("Deleted Note, ID: \(String(describing: note.id))")
//        } else {
            print("Note longitude (before uploading): \(String(describing: note.locationLongitude))")
            print("Note latitude (before uploading): \(String(describing: note.locationLatitude))")
            
            let supaNote = SupabaseNote(
                id: note.id ?? UUID(),
                owner_id: user.id, category_id: note.category?.id,
                content: note.attributedText.string,  // plain text
                rtf_content: base64RTF,              // fully styled
                date: note.date, locationName: note.locationName,
                locationLatitude: note.locationLatitude?.stringValue,
                locationLongitude: note.locationLongitude?.stringValue,
                colorString: note.category?.colorString ?? "",
                symbol: note.category?.symbol ?? "",
                isAnnonymous: note.isAnnonymous
            )
            
            if existInDB {
                if !note.isPublic {
                    let _ = try await SupabaseManager.shared.client
                        .from("public_notes")
                        .delete()
                        .eq("id", value: note.id)
                        .execute()
        
                    print("Deleted Note, ID: \(String(describing: note.id))")
                } else {
                    try await SupabaseManager.shared.client
                        .from("public_notes")
                        .update(supaNote)
                        .eq("id", value: note.id)
                        .execute()
                    print("Updated Note: \(String(describing: note.id))")
                }
            } else {
                try await SupabaseManager.shared.client
                    .from("public_notes")
                    .insert(supaNote)
                    .execute()
                print("Created Note: \(String(describing: note.id))")
            }
//        }

    } catch {
        print("error: (\(error))")
    }
}


@MainActor
func removeFromSupabase(note: Note) async {
    guard let noteID = note.id else { return }
    do {
        try await SupabaseManager.shared.client
            .from("public_notes")
            .delete()
            .eq("id", value: noteID)
            .execute()
        print("Deleted note \(noteID) from Supabase.")
    } catch {
        print("Error deleting from Supabase: \(error)")
    }
}

import CoreData

#Preview("Create Mode") {
    // 1) Create an in-memory Core Data container for previews
    let container = NSPersistentContainer(name: "Model")
    container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    container.loadPersistentStores { storeDescription, error in
        if let error = error {
            fatalError("Failed to load in-memory store for preview: \(error)")
        }
    }
    let viewContext = container.viewContext

    // 2) Create a sample Category
    let sampleCategory = Category(context: viewContext)
    sampleCategory.id = UUID()
    sampleCategory.name = "Test Category"
    sampleCategory.colorString = "blue"
    sampleCategory.symbol = "book"

    // 3) Show the NoteEditor in .create mode
    return NoteEditorView(
        mode: .create(sampleCategory),        // <— create
        categories: [sampleCategory],
        isAuthenticated: true,
        onSave: {
            do {
                try viewContext.save()
                print("Preview: saved context after creating note.")
            } catch {
                print("Preview: failed to save context: \(error)")
            }
        }
    )
    // Provide a managedObjectContext env for the note
    .environment(\.managedObjectContext, viewContext)
//    .environment(\.colorScheme, .dark)

}
