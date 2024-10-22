import SwiftUI
import CoreLocation
import RichTextKit

struct NoteEditorView: View {
    let categories: [Category]

    @State private var selectedDate: Date?
    @State private var attributedText: NSAttributedString
//    @State private var selectedImages: [UIImage]
    @State private var location: CLLocation?
    @State private var weather: String
    @State private var category: Category

    var note: Note?
    var onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var context  // Add the Core Data context here

    @State private var tapped: Bool = false
    @State private var showingImagePicker = false
    @State private var showingWeatherPicker = false
    @FocusState private var isTextEditorFocused: Bool

    // RichTextKit context
    @State private var contextRT = RichTextContext()  // Renamed to avoid conflict with Core Data context

    enum Mode {
        case edit(Note)
        case create(Category)
    }

    init(
        mode: Mode,
        categories: [Category],
        onSave: @escaping () -> Void
    ) {
        switch mode {
        case .edit(let note):
            self.init(
                note: note,
                categories: categories,
                category: note.category!,
                onSave: onSave
            )
        case .create(let category):
            self.init(
                note: nil,
                categories: categories,
                category: category,
                onSave: onSave
            )
        }
    }

    private init(
        note: Note?,
        categories: [Category],
        category: Category,
        onSave: @escaping () -> Void
    ) {
        self.note = note
        self.onSave = onSave

        _attributedText = State(initialValue: note?.attributedText ?? NSAttributedString())
        _location = State(initialValue: note?.location)
        _weather = State(initialValue: "")
        _tapped = State(initialValue: note != nil)
        _category = State(initialValue: category)
        _selectedDate = State(initialValue: note?.date)

        self.categories = categories
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
                    .frame(height: 200)
                    .padding(8)
                    .background(Color.white)
                    .focused($isTextEditorFocused)

                #if os(iOS)
                RichTextKeyboardToolbar(
                    context: contextRT,
                    leadingButtons: { $0 },
                    trailingButtons: { $0 },
                    formatSheet: { $0 }
                )
                #endif

//                // Image Selection View
//                ImageSelectionView(selectedImages: selectedImages)

                Spacer(minLength: 50)

                // Location and Weather Views
                HStack {
                    LocationView(location: $location)
                    
                    DateView(selectedDate: $selectedDate)
                        .padding(.leading, 5)

                    if !weather.isEmpty {
                        WeatherBar(weather: weather)
                            .padding(.leading, 5)
                            .padding(.bottom, 25)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    Spacer()
                }
            }
            .padding()
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

            ForEach(categories.filter { $0.name != self.category.name }, id: \.self) { categoryItem in
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

            Spacer()
        }
        .padding(.vertical, 5)
    }

    private func saveNote() {
        if !attributedText.string.isEmpty {
            if let existingNote = note {
                // Update existing note
                existingNote.attributedText = attributedText
                existingNote.date = selectedDate
//                existingNote.images = selectedImages
                existingNote.location = location
                existingNote.category = category
            } else {
                // Create new note in Core Data context
                let newNote = Note(context: context)
                newNote.id = UUID()
                newNote.attributedText = attributedText
//                newNote.images = selectedImages
                newNote.category = category
                newNote.date = selectedDate
                newNote.location = location
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
