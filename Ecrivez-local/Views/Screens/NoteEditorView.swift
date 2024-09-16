import SwiftUI
import MapKit

struct NoteEditorView: View {
    @State private var attributedText: NSAttributedString
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var selectedImages: [UIImage] = []
    @State private var location: CLLocation? // Make location optional
    @State private var weather: String
    @State private var category: Category?

    var note: Note?
    var onSave: (Note) -> Void
    @Environment(\.presentationMode) var presentationMode
    var placeholder: String = "Write down something..."

    @State private var tapped: Bool = false
    @State private var showingImagePicker = false
    @State private var showingWeatherPicker = false
    @State private var showingLocationPicker = false

    let categories: [Category] = [
        Category(symbol: "book", colorName: "green"),
        Category(symbol: "fork.knife", colorName: "blue"),
        Category(symbol: "sun.min", colorName: "yellow"),
        Category(symbol: "movieclapper", colorName: "pink"),
        Category(symbol: "clapperboard", colorName: "brown"),
        Category(symbol: "paperplane", colorName: "gray")
    ]

    init(note: Note? = nil, category: Category? = nil, onSave: @escaping (Note) -> Void, placeholder: String = "Write down something...") {
        self.note = note
        self.onSave = onSave
        self.placeholder = placeholder
        
        let initialText = note?.attributedText ?? NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.gray])
        _attributedText = State(initialValue: initialText)
        _selectedRange = State(initialValue: NSRange(location: 0, length: 0))
        _selectedImages = State(initialValue: note?.images ?? [])
        _location = State(initialValue: note?.location)
        _weather = State(initialValue: "")
        _tapped = State(initialValue: note != nil)
        _category = State(initialValue: note?.category ?? category)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Category Selection
                HStack(spacing: 17) {
                    Spacer()

                    // Display the selected category separately at the front, with a larger size
                    if let selectedCategory = category {
                        Circle()
                            .fill(selectedCategory.color)
                            .frame(width: 45, height: 45)
                            .overlay(
                                Image(systemName: selectedCategory.symbol)
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                    }

                    Spacer()

                    // Display the rest of the categories, excluding the selected one
                    ForEach(categories.filter { $0 != category }, id: \.self) { categoryItem in
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

                ZStack(alignment: .topLeading) {
                    if attributedText.string.isEmpty && !tapped {
                        let placeholderAttributedText = NSAttributedString(
                            string: placeholder,
                            attributes: [
                                .font: UIFont.systemFont(ofSize: 17),
                                .foregroundColor: UIColor.gray.withAlphaComponent(0.2)
                            ]
                        )

                        AttributedTextView(attributedText: placeholderAttributedText)
                            .padding(8)
                            .onTapGesture {
                                tapped = true
                                attributedText = NSAttributedString(string: "")
                            }
                    }

                    TextEditor(text: Binding(
                        get: { attributedText.string },
                        set: { attributedText = NSAttributedString(string: $0) }
                    ))
                    .frame(height: 200)
                    .padding(8)
                    .background(Color.white)
                }

                formattingToolbar

                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .padding()
                        }
                    }
                }
                Spacer(minLength: 50)
                HStack {
                    if let location = location {
                        LocationBar(location: location)
                            .padding(.leading, 5)
                            .padding(.bottom, 25)
                            .fixedSize(horizontal: true, vertical: false)
                    }

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
                if !attributedText.string.isEmpty || !selectedImages.isEmpty {
                    let newNote = Note(
                        id: note?.id ?? UUID(),
                        attributedText: attributedText,
                        images: selectedImages,
                        category: category ?? Category(symbol: "book", colorName: "green"),
                        location: location // Save the selected location
                    )
                    onSave(newNote)
                }
                presentationMode.wrappedValue.dismiss()
            })
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    Button(action: {
                        showingLocationPicker.toggle()
                    }) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                    }
                    
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
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(location: $location) // Pass binding to CLLocation
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
    }

    private var formattingToolbar: some View {
        HStack {
            Button(action: toggleBold) {
                Image(systemName: "bold")
            }
            .padding(.horizontal)

            Button(action: toggleItalic) {
                Image(systemName: "italic")
            }
            .padding(.horizontal)

            Button(action: addBulletPoint) {
                Image(systemName: "list.bullet")
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }

    private func toggleBold() {
        applyFontTrait(trait: .traitBold)
    }

    private func toggleItalic() {
        applyFontTrait(trait: .traitItalic)
    }

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

    private func addBulletPoint() {
        let bullet = "\u{2022} "
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let textLength = mutableText.length
        let safeLocation = min(selectedRange.location, textLength)
        mutableText.insert(NSAttributedString(string: bullet), at: safeLocation)
        attributedText = mutableText
        selectedRange = NSRange(location: safeLocation + bullet.count, length: 0)
    }
}

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    var placeholder: String
    var placeholderColor: UIColor = UIColor.gray.withAlphaComponent(0.5)
    var normalTextColor: UIColor = UIColor.label

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
        if attributedText.length == 0 {
            uiView.text = placeholder
            uiView.textColor = placeholderColor
        } else {
            uiView.attributedText = attributedText
            uiView.textColor = normalTextColor
        }

        let textLength = uiView.attributedText.length
        let safeLocation = min(selectedRange.location, textLength)
        let safeLength = min(selectedRange.length, textLength - safeLocation)
        let safeSelectedRange = NSRange(location: safeLocation, length: safeLength)

        if uiView.selectedRange != safeSelectedRange {
            uiView.selectedRange = safeSelectedRange
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView.textColor == parent.placeholderColor {
                parent.attributedText = NSAttributedString(string: "")
            } else {
                parent.attributedText = textView.attributedText
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == parent.placeholderColor {
                textView.text = nil
                textView.textColor = parent.normalTextColor
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = parent.placeholderColor
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let textLength = textView.attributedText.length
            let safeLocation = min(textView.selectedRange.location, textLength)
            let safeLength = min(textView.selectedRange.length, textLength - safeLocation)
            parent.selectedRange = NSRange(location: safeLocation, length: safeLength)
        }
    }
}


struct NoteEditorView_Previews: PreviewProvider {
    @State static var sampleAttributedText = NSAttributedString(string: "Sample Note Text")
    @State static var sampleImages: [UIImage] = []
    @State static var sampleLocation: String = "Sample Location"
    @State static var sampleWeather: String = "Sunny"
    @State static var selectedCategory: Category? = Category(symbol: "book", colorName: "green")

    static var previews: some View {
        // Use a simplified version of NoteEditorView for preview
        NoteEditorView(
            note: Note(
                id: UUID(),
                attributedText: sampleAttributedText,
                images: sampleImages,
                category: selectedCategory!
            ),
            onSave: { note in
                print("Note saved: \(note)")
            }
        )
//        .environment(\.presentationMode, .constant(.active))
        .previewLayout(.sizeThatFits)
    }
}
