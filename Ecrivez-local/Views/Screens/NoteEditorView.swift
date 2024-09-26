import SwiftUI
import CoreLocation

struct NoteEditorView: View {
    
    // if the view doesn't need to change the categories, it can just be initialized with let
    // doesn't need to be a binding
    
    let categories: [Category]

    // something inside the view can change those state vars
    // if something comes from outside and doesn't change it doesn't need to be a state, if it does it's a binding
    @State private var attributedText: NSAttributedString
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var selectedImages: [UIImage]
    @State private var location: CLLocation?
    @State private var weather: String
    @State private var category: Category

    // should we make note optional
    var note: Note?
    var onSave: (Note) -> Void
    @Environment(\.presentationMode) var presentationMode
    var placeholder: String = "Write down something..."

    @State private var tapped: Bool = false
    @State private var showingImagePicker = false
    @State private var showingWeatherPicker = false
    @FocusState private var isTextEditorFocused: Bool
    
    
    // Note: use the type system to make sure that we don't have both note and category as nil,
    
    // reduce down the possible inputs of this init so if a note is passed,
    // we rely on the note for the category
    
    
    // 2 Init can be a good option because they are used for different purposes
    // can also use enum
    
    init (
        category: Category,
        categories: [Category],
        onSave: @escaping (Note) -> Void,
        placeholder: String = "Write something down..."
    ) {
        self.init(
            note: nil,
            categories: categories,
            category: category,
            onSave: onSave,
            placeholder: placeholder
        )
        
        
        
    }

    
    init (
        note: Note,
        categories: [Category],
        onSave: @escaping (Note) -> Void,
        placeholder: String = "Write something down..."
    ) {
        self.init(
            note: note,
            categories: categories,
            category: note.category,
            onSave: onSave,
            placeholder: placeholder
        )
    }
    
    private init(
        note: Note?,
        categories: [Category],
        category: Category,
        onSave: @escaping (Note) -> Void,
        placeholder: String
    ) {
        self.note = note
        self.onSave = onSave
        self.placeholder = placeholder

        // Get the category from the note if it's available and no explicit category is provided
        
        let initialText = note?.attributedText ?? NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.gray.withAlphaComponent(0.5)])
        _attributedText = State(initialValue: initialText)
//        _selectedRange = State(initialValue: NSRange(location: 0, length: 0))
        // don't set things twice
        _selectedImages = State(initialValue: note?.images ?? [])
        _location = State(initialValue: note?.location)
        _weather = State(initialValue: "")
        _tapped = State(initialValue: note != nil)
        _category = State(initialValue: category)
        
        self.categories = categories
    }

    var body: some View {
        NavigationView {
            VStack {
                // Category Selection
                categorySelectionView

                ZStack(alignment: .topLeading) {
                    if attributedText.string.isEmpty && !isTextEditorFocused {
                        Text(placeholder)
                            .foregroundColor(Color.gray.opacity(0.5))
                            .padding(.leading, 8)
                            .padding(.top, 12)
                    }

                    TextEditor(text: Binding(
                        get: { attributedText.string },
                        set: { newText in
                            attributedText = NSAttributedString(string: newText)
                        }
                    ))
                    .frame(height: 200)
                    .padding(8)
                    .background(Color.white)
                    .focused($isTextEditorFocused)
                }

                // Formatting Toolbar
                FormattingToolbar(
                    toggleBold: toggleBold,
                    toggleItalic: toggleItalic,
                    addBulletPoint: addBulletPoint
                )

                // Image Selection View
                ImageSelectionView(selectedImages: selectedImages)

                Spacer(minLength: 50)

                // Location and Weather Views
                HStack {
                    LocationView(location: $location)

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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages)
            }
            .sheet(isPresented: $showingWeatherPicker) {
                WeatherPicker(weather: $weather)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
//        .onAppear {
//            if let initialCategory = self.category {
//                print("Initial category: \(initialCategory.symbol) with color: \(initialCategory.colorName)")
//            } else {
//                print("No initial category set")
//            }
//        }

    }

    private var categorySelectionView: some View {
        HStack(spacing: 17) {
            Spacer()

            Circle()
                .fill(category.color)
                .frame(width: 45, height: 45)
                .overlay(
                    Image(systemName: category.symbol)
                        .foregroundColor(.white)
                        .font(.title2)
                )

            Spacer()

            ForEach(categories.filter { $0 != self.category }, id: \.self) { categoryItem in
                
                Button(action: {
                    self.category = categoryItem
                }) {
                    Circle()
                        .fill(categoryItem.color)
                        .frame(width: 35, height: 35)
                        .overlay(
                            Image(systemName: categoryItem.symbol)
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
        if !attributedText.string.isEmpty || !selectedImages.isEmpty {
            let newNote = Note(
                id: note?.id ?? UUID(),
                attributedText: attributedText,
                images: selectedImages,
                category: category,
                location: location
            )
            onSave(newNote)
        }
        presentationMode.wrappedValue.dismiss()
    }

    // Formatting functions (same as before)
    private func addBulletPoint() {
        let bullet = "\u{2022} "
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let textLength = mutableText.length
        let safeLocation = min(selectedRange.location, textLength)
        
        // use UITextView and wrap it inside UIViewRepresentable
        // https://stackoverflow.com/a/77044684/255489
        // can build an Editor with Attributed String as an exercise,
        // but there are also libaries
        
        mutableText.insert(NSAttributedString(string: bullet), at: safeLocation)
        attributedText = mutableText
        selectedRange = NSRange(location: safeLocation + bullet.count, length: 0)
    }

    private func toggleBold() {
        applyFontTrait(trait: .traitBold)
    }

    private func toggleItalic() {
        applyFontTrait(trait: .traitItalic)
    }
}


import UIKit // Required for UIFontDescriptor and symbolic traits

extension NoteEditorView {
    private func applyFontTrait(trait: UIFontDescriptor.SymbolicTraits) {
        let textLength = attributedText.length
        let safeLocation = min(selectedRange.location, textLength)
        let safeLength = min(selectedRange.length, textLength - safeLocation)
        let safeSelectedRange = NSRange(location: safeLocation, length: safeLength)

        guard safeSelectedRange.length > 0 else { return }

        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        mutableText.enumerateAttributes(in: safeSelectedRange, options: []) { attributes, range, _ in
            let currentFont = attributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 17)
            var newTraits = currentFont.fontDescriptor.symbolicTraits

            if newTraits.contains(trait) {
                newTraits.remove(trait)
            } else {
                newTraits.insert(trait)
            }

            if let newDescriptor = currentFont.fontDescriptor.withSymbolicTraits(newTraits) {
                let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                mutableText.addAttribute(.font, value: newFont, range: range)
            }
        }

        attributedText = mutableText
    }
}
