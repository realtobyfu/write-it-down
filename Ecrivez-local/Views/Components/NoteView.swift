//
//  NoteView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 10/8/24.
//
import SwiftUI
import UIKit

struct NoteView: View {
    let note: Note
    @Binding var selectedNote: Note?
    @Binding var showingNoteEditor: Bool
    @Binding var deleteMode: Bool
    var onDelete: (() -> Void)? = nil // Optional delete callback

    // Computed property to adjust the attributed text
    private var adjustedAttributedText: NSAttributedString {
        // Create a mutable copy of the attributed text
        let mutableAttributedText = NSMutableAttributedString(attributedString: note.attributedText)
        
        // Define the new font size and color
        let newFontSize: CGFloat = 18
        let newTextColor: UIColor = .white
        
        // Enumerate and modify attributes
        mutableAttributedText.enumerateAttributes(
            in: NSRange(location: 0, length: mutableAttributedText.length),
            options: []
        ) { attributes, range, _ in
            var modifiedAttributes = attributes
            
            // Adjust the font size while retaining existing font traits
            if let font = attributes[.font] as? UIFont {
                let fontDescriptor = font.fontDescriptor
                let newFont = UIFont(descriptor: fontDescriptor, size: newFontSize)
                modifiedAttributes[.font] = newFont
            } else {
                // If no font attribute is present, set a default font
                modifiedAttributes[.font] = UIFont.systemFont(ofSize: newFontSize)
            }
            
            // Change the text color
            modifiedAttributes[.foregroundColor] = newTextColor
            
            // Apply the modified attributes to the range
            mutableAttributedText.setAttributes(modifiedAttributes, range: range)
        }
        
        return mutableAttributedText
    }
    
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
                    
                    // Display the modified attributed text using AttributedTextView
                    AttributedTextView(attributedText: adjustedAttributedText)
                        .onTapGesture {
                            selectedNote = note
                            showingNoteEditor = true
                        }
                }
                Spacer()
                
                if deleteMode {
                    Button(action: {
                        onDelete?()
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
        .background(note.category.color) // Apply the note color to the background
        .cornerRadius(20)
        .padding(.vertical, 2)
        .listRowSeparator(.hidden)
        .foregroundColor(.white)
    }
}
