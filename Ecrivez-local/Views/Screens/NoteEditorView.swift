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
            VStack {
                
#if os(macOS)
                RichTextFormat.Toolbar(context: contextRT)
#endif
                
                // Category Selection
                categorySelectionView
                
                RichTextEditor(text: $viewModel.attributedText, context: contextRT, format: .archivedData)
                    .padding(8)
                //                    .background(Color.background)
                    .foregroundStyle(Color.background)
                    .focused($isTextEditorFocused)
//                    .focusedValue(\.richTextContext, contextRT)

#if os(iOS)
                RichTextKeyboardToolbar(
                    context: contextRT,
                    leadingButtons: { $0 },
                    trailingButtons: {
                        _ in
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
//                // changes is not published in contextRT
                .onReceive(contextRT.actionPublisher) { action in
                    // Capture all formatting actions and update  the view model
                    
                    // DEBUG: Currently, sometimes font gets updated in contextRT but not viewModel + context
                    // SOLUTION: manually overwrite the string in viewModel because it's what's going to be saved

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
                
                if isAuthenticated {
                    HStack(spacing: 16) {
                        // Public Toggle
                        Toggle("Make Public", isOn: $viewModel.isPublic)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        // Only show Anonymous toggle when Public is enabled
                        if viewModel.isPublic {
                            Divider()
                                .frame(height: 24)
                            
                            Toggle("Anonymous", isOn: $viewModel.isAnonymous)
                                .toggleStyle(SwitchToggleStyle(tint: .gray))
                        }
                    }
                    .padding(.vertical, 8)
                }
                // Location Picker View
                HStack {
                    if let location = viewModel.location {
                        // Display the location bar if location is selected
                        LocationSelectionBar(location: viewModel.location!, placeName: viewModel.locationName!)
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
                    DateView(selectedDate: $viewModel.selectedDate)
                        .padding(.leading, 5)
                    
                    if !viewModel.weather.isEmpty {
                        WeatherBar(weather: viewModel.weather)
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
            
            .padding([.leading, .trailing])
            .navigationBarTitle(navigationTitleText, displayMode: .inline)
            .navigationBarItems(trailing:
                Button("Done") {
                    Task {
                        await viewModel.saveNote(isAuthenticated: isAuthenticated)
                        presentationMode.wrappedValue.dismiss()
                        onSave()
                    }
                }.disabled(viewModel.attributedText.string.isEmpty)
            )
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
                        isShowingImagePicker = true
                    }) {
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                            .padding(5)
                    }
                }
            }
            .sheet(isPresented: $showingWeatherPicker) {
                WeatherPicker(weather: $viewModel.weather)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingLocationPicker) {
                // pass $location, $locationName AND $locationLocality
                LocationPickerView(
                    location: $viewModel.location,
                    locationName: $viewModel.locationName,
                    locationLocality: $viewModel.locationLocality
                )
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
