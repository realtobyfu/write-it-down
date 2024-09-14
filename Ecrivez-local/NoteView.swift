//
//  NoteView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 7/31/24.
//

import SwiftUI

struct NoteView: View {
    @State var note: Note
    var onSave: (Note) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextField("Edit note", text: $note.text)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .background(Color.white)
            
            if !note.images.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(note.images, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .padding()
                        }
                    }
                }
            }
            
            Button(action: {
                onSave(note)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Save")
            }
            .padding()
        }
        .navigationTitle("Edit Note")
        .background(Color.white)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                }
            }
        }
    }
}
