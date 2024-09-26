//
//  CardView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI


struct NoteListView: View {
    var notes: [Note]
    var onSelectNote: (Note) -> Void
    var onDeleteNote: (Note) -> Void
    var deleteMode: Bool
    
    var body: some View {
        List {
            ForEach(notes) { note in
                VStack {
                    HStack {
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
                            Image(systemName: note.category.symbol)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 10)

                            let attributedText = NSAttributedString(
                                string: note.attributedText.string,
                                attributes: [
                                    .font: UIFont.systemFont(ofSize: 18),
                                    .foregroundColor: UIColor.white
                                ]
                            )
                            AttributedTextView(attributedText: attributedText)
                                .onTapGesture {
                                    onSelectNote(note)
                                }
                                .foregroundColor(.white)
                        }
                        Spacer()

                        if deleteMode {
                            Button(action: {
                                onDeleteNote(note)
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
                .foregroundColor(.white)
            }
        }
        .listStyle(PlainListStyle())
    }
}
