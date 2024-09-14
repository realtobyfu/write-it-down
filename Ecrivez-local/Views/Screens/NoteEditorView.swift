import SwiftUI

struct NoteEditorView: View {
    
    @State private var newNoteText: String
    var onAdd: (Note) -> Void
    @Environment(\.presentationMode) var presentationMode
    var placeholder: String = "Write down something..."
    @State private var tapped: Bool
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingWeatherPicker = false
    @State private var location = "New York"
    @State private var weather = ""
    
    init(onAdd: @escaping (Note) -> Void, placeholder: String = "Write down something...") {
        self.onAdd = onAdd
        self.placeholder = placeholder
        _newNoteText = State(initialValue: placeholder)
        self.tapped = false
    }

    var body: some View {
        NavigationView {
            VStack {

                TextEditor(text: $newNoteText)
                    .foregroundColor(newNoteText == placeholder ? .gray : .primary)
                    .padding()
                    .background(Color.white)
                    .onTapGesture {
                        if newNoteText == placeholder {
                            self.tapped = true
                            newNoteText = ""
                        }
                    }
                    .onChange(of: newNoteText) { _ in
                        if !tapped && newNoteText.isEmpty {
                            self.newNoteText = placeholder
                        }
                    }

                // Scroll view for photos
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
                    if weather != "" {
                        WeatherBar(weather: weather)
                            .frame(width: weather.count > 5 ? 200 : 150, height: 30)
                            .padding(.leading, 5)
                            .padding(.bottom, 25)
//                            .padding(.top, 10) // Add some padding from the top
                    }
                    Spacer()
                }

            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if (newNoteText != placeholder && !newNoteText.isEmpty) || !selectedImages.isEmpty {
                            onAdd(Note(text: newNoteText, images: selectedImages))
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                    }
                }
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
