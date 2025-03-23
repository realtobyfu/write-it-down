import SwiftUI

import CoreLocation
import RichTextKit

struct NoteEditorView: View {
    
    enum Mode {
        case edit(Note)
        case create(Category)
    }

    // MARK: - Stored Properties

    let mode: Mode
    let categories: [Category]
    let onSave: () -> Void
    let isAuthenticated: Bool
    private let note: Note?

    // MARK: - States
    @State private var selectedDate: Date?
    @State private var attributedText: NSAttributedString
    @State private var location: CLLocationCoordinate2D?
    @State private var weather: String
    @State private var category: Category
    @State private var isPublic: Bool
    @State private var isAnnonymous: Bool
    @State private var locationName: String?

    // Other states...
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.managedObjectContext) private var context

    @State private var tapped = false
    @State private var showingImagePicker = false
    @State private var showingWeatherPicker = false
    @State private var showingLocationPicker = false
    @FocusState private var isTextEditorFocused: Bool

    @StateObject private var contextRT = RichTextContext()

    enum ImageSourceType {
        case camera
        case photoLibrary
    }

    @State private var isConfirmationDialogPresented = false
    @State private var isShowingImagePicker = false
    @State private var imageSourceType: ImageSourceType = .photoLibrary
    @State private var inputImage: UIImage?

    // MARK: - Initializer

    init(
        mode: Mode,
        categories: [Category],
        isAuthenticated: Bool,
        onSave: @escaping () -> Void
    ) {
        // Set basic let properties directly
        self.mode = mode
        self.categories = categories
        self.isAuthenticated = isAuthenticated
        self.onSave = onSave

        // Placeholder vars
        var noteForEdit: Note?
        var initialAttributedText = NSAttributedString()
        var initialDate: Date?
        var initialIsPublic = false
        var initialIsAnnonymous = false
        var initialLocation: CLLocationCoordinate2D?
        var initialLocationName: String?
        var initialWeather = ""
        var initialCategory: Category

        // Populate placeholders based on mode
        switch mode {
        case .edit(let existingNote):
            noteForEdit = existingNote
            initialAttributedText = existingNote.attributedText
            initialDate = existingNote.date
            initialIsPublic = existingNote.isPublic
            initialIsAnnonymous = existingNote.isAnnonymous
            initialLocation = existingNote.location?.coordinate
            initialLocationName = existingNote.placeName
            initialCategory = existingNote.category ?? categories.first!

        case .create(let category):
            noteForEdit = nil
            initialCategory = category
        }

        // Set state properties
        _attributedText = State(initialValue: initialAttributedText)
        _selectedDate = State(initialValue: initialDate)
        _isPublic = State(initialValue: initialIsPublic)
        _isAnnonymous = State(initialValue: initialIsAnnonymous)
        _location = State(initialValue: initialLocation)
        _locationName = State(initialValue: initialLocationName)
        _weather = State(initialValue: initialWeather)
        _category = State(initialValue: initialCategory)

        // Set the private note property
        self.note = noteForEdit
    }

    // MARK: - Computed Properties

    private var navigationTitleText: String {
        switch mode {
        case .edit(_): return "Edit Note"
        case .create(_): return "New Note"
        }
    }


    
    //
//    private init(
//        isAuthenticated : Bool,
//        note: Note?,
//        categories: [Category],
//        category: Category,
//        onSave: @escaping () -> Void
//    ) {
//        
//        self.note = note
//        self.onSave = onSave
//        self.categories = categories
//        self.isAuthenticated = isAuthenticated
//
//        _attributedText = State(initialValue: note?.attributedText ?? NSAttributedString())
//        _location = State(initialValue: note?.location?.coordinate)  // Make location optional
//        _weather = State(initialValue: "")  // Weather can be fetched or updated
//        _tapped = State(initialValue: note != nil)
//        _category = State(initialValue: category)
//        _selectedDate = State(initialValue: note?.date)
//        _isPublic = State(initialValue: note?.isPublic ?? false)
//        _locationName  = State(initialValue: note?.placeName)


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
                    trailingButtons: { _ in
                        // Add this
                        Button(action: {
                            isConfirmationDialogPresented = true
                        }, label: {
                            Image(systemName: "photo")
                        })
                    },
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
            .confirmationDialog(
                "Select Image Source",
                isPresented: $isConfirmationDialogPresented,
                actions: {
                    // If you want camera:
                    Button("Camera") {
                        imageSourceType = .camera
                        isShowingImagePicker = true
                    }
                    // Or library:
                    Button("Photo Library") {
                        imageSourceType = .photoLibrary
                        isShowingImagePicker = true
                    }
                },
                message: {
                    Text("Where do you want to pick an image from?")
                }
            )

            .sheet(isPresented: $isShowingImagePicker, onDismiss: {
                // Once the sheet is dismissed, see if we got a valid UIImage
                if let inputImage {
                    // Insert that image into the RichTextEditor at the cursor
                    let cursorLocation = contextRT.selectedRange.location
                    let insertion = RichTextInsertion<UIImage>.image(inputImage,
                                                                     at: cursorLocation,
                                                                     moveCursor: true)
                    let action = RichTextAction.pasteImage(insertion)
                    contextRT.handle(action)
                    
                    // Clear out the input
                    self.inputImage = nil
                }
            }) {
                switch imageSourceType {
                case .camera:
                    CameraImagePicker(image: $inputImage, sourceType: .camera)
                case .photoLibrary:
                    PhotoLibraryPicker(selectedImage: $inputImage)
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
            .navigationBarTitle(navigationTitleText, displayMode: .inline)
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
