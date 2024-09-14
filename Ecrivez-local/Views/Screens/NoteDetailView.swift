import SwiftUI
import PhotosUI

struct NoteDetailView: View {
    @Binding var note: Note
    @State private var isEditing = false
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                if isEditing {
                    TextEditor(text: $note.text)
                        .foregroundColor(note.text.isEmpty ? .gray : .primary)
                        .padding()
                        .background(Color.white)
                        .onTapGesture {
                            if note.text.isEmpty {
                                note.text = ""
                            }
                        }
                } else {
                    Text(note.text)
                        .padding()
                }

                if !note.images.isEmpty || isEditing {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(note.images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .padding()
                            }
                            if isEditing {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .padding()
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
//            .navigationTitle(isEditing ? "Edit Note" : "Note Detail")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if isEditing {
                            note.images.append(contentsOf: selectedImages)
                            selectedImages.removeAll()
                            presentationMode.wrappedValue.dismiss()
                        }
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    if isEditing {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .padding(5)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages)
            }
        }
    }
}

struct NoteDetailView_Previews: PreviewProvider {
    @State static var dummyNote = Note(text: "This is a sample note text", images: [UIImage(systemName: "photo")!])

    static var previews: some View {
        NoteDetailView(note: $dummyNote)
    }
}
