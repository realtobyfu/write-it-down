import SwiftUI
import Combine
import CoreLocation
import RichTextKit
import CoreData

struct NoteEditorView: View {
    
    enum Mode {
        case edit(Note)
        case create(Category)
    }
    
    @StateObject private var viewModel: NoteEditorViewModel
    private let categories: [Category]
    private let isAuthenticated: Bool
    private let onSave: () -> Void
    private let mode: Mode
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        mode: Mode,
        categories: [Category],
        context: NSManagedObjectContext,
        isAuthenticated: Bool,
        onSave: @escaping () -> Void
    ) {
        // 1) Build the VM
        _viewModel = StateObject(wrappedValue: NoteEditorViewModel(mode: mode, context: context))
        
        self.categories = categories
        self.isAuthenticated = isAuthenticated
        self.onSave = onSave
        self.mode = mode
    }
    
    private var navigationTitleText: String {
        viewModel.existingNote == nil ? "New Note" : "Edit Note"
    }
    
    //    // MARK: - States
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
    
    

    // MARK: - Computed Properties
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
#if os(macOS)
                RichTextFormat.Toolbar(context: contextRT)
#endif
                
                EnhancedCategorySelectionView(
                    selectedCategory: $viewModel.category,
                    categories: categories
                )
                
                RichTextEditor(text: $viewModel.attributedText, context: contextRT, format: .archivedData)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                    .focused($isTextEditorFocused)

#if os(iOS)
                RichTextKeyboardToolbar(
                    context: contextRT,
                    leadingButtons: { $0 },
                    trailingButtons: { _ in EmptyView() },
                    formatSheet: { $0 }
                )
                .richTextKeyboardToolbarConfig(
                    .init(
                        leadingActions: [ .undo, .redo ],
                        trailingActions: [ ]
                    )
                )
                .onReceive(contextRT.actionPublisher) { action in
                    print("Received Change: ", action)
                    print("contextRT.fontSize:", contextRT.fontSize)
                    print("contextRT.fontName:", contextRT.fontName)
                    print("contextRT.styles:", contextRT.styles)
                    
                    let mutable = NSMutableAttributedString(attributedString: viewModel.attributedText)
                    
                    if contextRT.hasSelectedRange {
                        let range = contextRT.selectedRange
                    }

                    print("contextRT.attributedString", contextRT.attributedString)
                    print("viewModel.attributedText", viewModel.attributedText)
                }
                .onChange(of: viewModel.attributedText) { old, new in
                    print("Old value (viewModel.attributedText):", old)
                    print("New value (viewModel.attributedText):", new)
                }
#endif
                
                PrivacyToggleView(
                    isPublic: $viewModel.isPublic,
                    isAnonymous: $viewModel.isAnonymous,
                    isAuthenticated: isAuthenticated
                )

                NoteMetadataView(
                    selectedDate: $viewModel.selectedDate,
                    location: $viewModel.location,
                    locationName: $viewModel.locationName,
                    locationLocality: $viewModel.locationLocality,
                    weather: $viewModel.weather,
                    showingLocationPicker: $showingLocationPicker,
                    showingWeatherPicker: $showingWeatherPicker,
                    showingImagePicker: $isShowingImagePicker,
                    imageSourceType: $imageSourceType
                )
            }
            .padding()
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
                guard let rawImage = inputImage else { return }

                // Choose a maximum width that fits inside your text view.
                let maxWidth: CGFloat = UIScreen.main.bounds.width - 32     // ≈ side padding

                // ---- Resize while keeping the aspect ratio ----
                let scale = min(1, maxWidth / rawImage.size.width)
                let newSize = CGSize(width:  rawImage.size.width  * scale,
                                     height: rawImage.size.height * scale)

                UIGraphicsBeginImageContextWithOptions(newSize, false, rawImage.scale)
                rawImage.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? rawImage
                UIGraphicsEndImageContext()
                // ----------------------------------------------

                // Insert the (already‑sized) bitmap
                let cursor = contextRT.selectedRange.location
                let insertion = RichTextInsertion<UIImage>.image(
                    resizedImage,
                    at: cursor,
                    moveCursor: true
                )
                contextRT.handle(.pasteImage(insertion))

                inputImage = nil
            }) {
                switch imageSourceType {
                case .camera:
                    CameraImagePicker(image: $inputImage, sourceType: .camera)
                case .photoLibrary:
                    PhotoLibraryPicker(selectedImage: $inputImage)
                }
            }

            .onAppear {
                // Overwrite text color for entire string
                let mutable = NSMutableAttributedString(attributedString: viewModel.attributedText)
                
                let entireRange = NSRange(location: 0, length: mutable.length)
                
                // 1) Remove any existing foreground color
                mutable.removeAttribute(.foregroundColor, range: entireRange)
                
                // 2) Add the color we want
                let newColor: UIColor = (colorScheme == .dark) ? .white : .black
                mutable.addAttribute(.foregroundColor, value: newColor, range: entireRange)
                
                // 3) Assign back
                viewModel.attributedText = mutable
                
                print("Updated note:", viewModel.attributedText) // Just to confirm
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .principal) {
                    Text(navigationTitleText)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                    Task {
                        await viewModel.saveNote(isAuthenticated: isAuthenticated)
                        presentationMode.wrappedValue.dismiss()
                        onSave()
                    }
                    }) {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save").bold()
                }
            }
                    .disabled(viewModel.attributedText.string.isEmpty || viewModel.isSaving)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(
                    location: $viewModel.location,
                    locationName: $viewModel.locationName,
                    locationLocality: $viewModel.locationLocality
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingWeatherPicker) {
                WeatherPicker(weather: $viewModel.weather)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    private var categorySelectionView: some View {
        HStack(spacing: 17) {
            Spacer()
            
            Circle()
                .fill(viewModel.category.color)
                .frame(width: 45, height: 45)
                .overlay(
                    Image(systemName: viewModel.category.symbol!)
                        .foregroundColor(.white)
                        .font(.title2)
                )
            
            Spacer()
            
            if categories.count > 6 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 17) {
                        ForEach(categories.sorted(by: {$0.index < $1.index }).filter { $0.name != self.viewModel.category.name }, id: \.self) { categoryItem in
                            Button(action: {
                                self.viewModel.category = categoryItem
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
                ForEach(categories.sorted(by: {$0.index < $1.index }).filter { $0.name != self.viewModel.category.name }, id: \.self) { categoryItem in
                    Button(action: {
                        self.viewModel.category = categoryItem
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
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(category.color)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .overlay(
                        Image(systemName: category.symbol ?? "circle")
                            .foregroundColor(.white)
                            .font(isSelected ? .title3 : .body)
                    )
                    .shadow(radius: isSelected ? 2 : 0)
                
                if let name = category.name, !name.isEmpty {
                    Text(name)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

    

private func processImageForStorage(_ image: UIImage) -> UIImage {
    // Resize large images to prevent excessive storage usage
    let maxDimension: CGFloat = 1200
    
    let originalSize = image.size
    var newSize = originalSize
    
    if originalSize.width > maxDimension || originalSize.height > maxDimension {
        if originalSize.width > originalSize.height {
            let ratio = maxDimension / originalSize.width
            newSize = CGSize(width: maxDimension, height: originalSize.height * ratio)
        } else {
            let ratio = maxDimension / originalSize.height
            newSize = CGSize(width: originalSize.width * ratio, height: maxDimension)
        }
    }
    
    // If no resizing needed, return original
    if newSize == originalSize {
        return image
    }
    
    // Create a new resized image
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
    UIGraphicsEndImageContext()
    
    return resizedImage
}

#if DEBUG
struct NoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        // In-memory Core Data container for preview
        let container: NSPersistentContainer = {
            let c = NSPersistentContainer(name: "Model")
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            c.persistentStoreDescriptions = [desc]
            c.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("Unresolved error \(error)")
                }
            }
            return c
        }()
        let context = container.viewContext
        
        // Sample categories
        let cat1 = Category(context: context)
        cat1.id = UUID()
        cat1.name = "Personal"
        cat1.symbol = "person"
        cat1.colorString = "blue"
        cat1.index = 0
        
        let cat2 = Category(context: context)
        cat2.id = UUID()
        cat2.name = "Work"
        cat2.symbol = "briefcase"
        cat2.colorString = "green"
        cat2.index = 1
        
        let categories = [cat1, cat2]
        
        return NoteEditorView(
            mode: .create(categories.first!),
            categories: categories,
            context: context,
            isAuthenticated: true,
            onSave: {}
        )
    }
}
#endif
