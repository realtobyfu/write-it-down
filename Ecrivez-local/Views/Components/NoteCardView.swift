//
//  CardView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct NoteCardView: View {
    var note: Note
    @Binding var deleteMode: Bool // Use Binding here
    
    var onDelete: (Note) -> Void // Action to delete the note

    var body: some View {
        VStack {
            HStack {
                // Image Scrolling
                if !note.images.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(note.images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    // Category Symbol on top of the text
                    Image(systemName: note.category.symbol)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)

                    // Construct NSAttributedString with font and color
                    let attributedText = NSAttributedString(
                        string: note.attributedText.string,
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 18),
                            .foregroundColor: UIColor.white
                        ]
                    )

                    AttributedTextView(attributedText: attributedText)
                        .foregroundColor(.white)
                }
                Spacer()
                
                // Delete Button appears if deleteMode is active
                if deleteMode {
                    Button(action: {
                        onDelete(note)
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
        .background(note.category.color)
        .cornerRadius(20)
        .padding(.vertical, 2)
        .listRowSeparator(.hidden)
    }
}
