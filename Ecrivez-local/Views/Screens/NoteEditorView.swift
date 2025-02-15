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
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var context  // Core Data context

    @State private var tapped: Bool = false
    @State private var showingImagePicker = false
    @State private var showingWeatherPicker = false
    @State private var showingLocationPicker = false  // State to control the presentation of LocationPickerView
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

        _attributedText = State(initialValue: note?.attributedText ?? NSAttributedString())
        _location = State(initialValue: note?.location?.coordinate)  // Make location optional
        _weather = State(initialValue: "")  // Weather can be fetched or updated
        _tapped = State(initialValue: note != nil)
        _category = State(initialValue: category)
        _selectedDate = State(initialValue: note?.date)
        _isPublic = State(initialValue: note?.isPublic ?? false)

        self.categories = categories
        self.isAuthenticated = isAuthenticated
    }

    var body: some View {
        NavigationView {
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
                #endif
                
                if isPublic {
                    Toggle("Annonymous Post?", isOn: $isAnnonymous)
                        .padding(.vertical, 0)
                }
                
                if isAuthenticated {
                    Toggle("Make Public", isOn: $isPublic)
                        .padding(.vertical, 8)
                }
                

                // Location Picker View
                HStack {
                    if let location = location {
                        // Display the location bar if location is selected
                        LocationSelectionBar(location: location)
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
                LocationPickerView(location: $location)
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
        if !attributedText.string.isEmpty {
            
            if let existingNote = note {
                // Update existing note
                existingNote.attributedText = attributedText
                existingNote.date = selectedDate
                existingNote.category = category
                existingNote.isPublic = isPublic
                existingNote.isAnnonymous = isAnnonymous
                existingNote.location = location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
                
                Task {
                    await updateSupabase(note: existingNote)
                }
            } else {
                // Create new note
                let newNote = Note(context: context)
                newNote.id = UUID()
                newNote.attributedText = attributedText
                newNote.category = category
                newNote.date = selectedDate
                newNote.isAnnonymous = isAnnonymous
                newNote.location = location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
                
                if newNote.isPublic && isAuthenticated {
                    Task {
                        await updateSupabase(note: newNote)
                    }
                }
            }
            
            // Save the context
            do {
                try context.save()
            } catch {
                print("Failed to save note: \(error)")
            }

            // Dismiss and call the onSave closure
            presentationMode.wrappedValue.dismiss()
            onSave()
        }
    }
}

@MainActor
func updateSupabase(note: Note) async {
    
    do {
        let user = try await SupabaseManager.shared.client.auth.user()
        
        print("ID of the user: \(user.id)")
        
        
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
                content: note.attributedText.string,
                date: note.date,
                locationLongitude: note.locationLatitude?.doubleValue,
                locationLatitude: note.locationLongitude?.doubleValue,
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




//struct SupabaseCategory: Codable {
//    let id: UUID
//    let name: String
//    let symbol: String
//    let colorString: String
//    
//    init (id: UUID, name: String, symbol: String, colorString: String)
//}
//
struct SupabaseNote: Codable, Identifiable {
    // Matching your DB columns:
    let id: UUID        // or Int
    let owner_id: UUID
    
    let category_id: UUID?    // if using a separate categories table
    let content: String       // either plain text or base64
    
    // optional attributes
    var date: Date? = nil
    var locationLongitude: Double? = nil
    var locationLatitude: Double? = nil
    
    var isAnnonymous: Bool?
    
    // temporary solution: store the color string inside note in db
    let colorString: String
    let symbol: String
    
    var profiles: ProfileData? = nil
    
    struct ProfileData: Codable {
        let username: String?
    }

    
    // MARK: - Custom Keys
    private enum CodingKeys: String, CodingKey {
        case id, owner_id, category_id
        case content, date, locationLongitude, locationLatitude
        case isAnnonymous
        case colorString, symbol
        case profiles
    }

    // MARK: - Custom Decoder (for the "YYYY-MM-DD" date)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        self.id = try container.decode(UUID.self, forKey: .id)
        self.owner_id = try container.decode(UUID.self, forKey: .owner_id)
        self.category_id = try container.decodeIfPresent(UUID.self, forKey: .category_id)
        self.content = try container.decode(String.self, forKey: .content)
        self.colorString = try container.decode(String.self, forKey: .colorString)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        
        // Date stored as "YYYY-MM-DD" in Supabase
        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.date = formatter.date(from: dateString)
        } else {
            self.date = nil
        }
        
        
        self.isAnnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnnonymous)

        // Optional floats for location
        self.locationLongitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
        self.locationLatitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
        
        self.profiles = try container.decodeIfPresent(ProfileData.self, forKey: .profiles)
    }
    
    init(id: UUID,
         owner_id: UUID,
         category_id: UUID?,
         content: String,
//         created_at: String?,
         date: Date?,
         locationLongitude: Double?,
         locationLatitude: Double?,
         colorString: String,
         symbol: String,
         isAnnonymous: Bool
    ) {
        self.id = id
        self.owner_id = owner_id
        self.category_id = category_id
        self.content = content
        
        if let lat = locationLatitude, let lon = locationLongitude {
            self.locationLatitude = lat
            self.locationLongitude = lon
        }

        if date != nil {
            self.date = date
        }
        
        self.isAnnonymous = isAnnonymous
        self.colorString = colorString
        self.symbol = symbol
        
        print("locationLatitude: \(String(describing: self.locationLatitude))")
        print("locationLongitude: \(String(describing: self.locationLongitude))")
    }
}
