    //
    //  NoteView.swift
    //  Ecrivez-local
    //
    //  Created by Tobias Fu on 10/8/24.
    //
import SwiftUI
import CoreLocation

struct NoteView: View {
    let note: Note
    @Binding var selectedNote: Note?
    @Binding var showingNoteEditor: Bool
    
    @State private var dynamicHeight: CGFloat = .zero
    @State private var locationString: String = ""
    
    var body: some View {
        // Wrap the entire cell in a Button
        Button {
            selectedNote = note
            showingNoteEditor = true
        } label: {
            // Cell content
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        headerView
                        
                        AttributedTextView(
                            attributedText: adjustedAttributedText,
                            dynamicHeight: $dynamicHeight
                        )
                        .frame(height: dynamicHeight)
                    }
                    Spacer()
                }
                .padding()
            }
            .background(note.category?.color ?? .gray)
            .cornerRadius(20)
            .padding(.vertical, 2)
            .listRowSeparator(.hidden) // So the row separator doesn't overlay
            .foregroundColor(.white)
            .onAppear {
                reverseGeocodeIfNeeded()
            }
        }
        // Make the button look/act like a tap gesture (no default button styling)
        .buttonStyle(.plain)
        // Ensure the entire rectangle is the tap target
        .contentShape(Rectangle())
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            if let symbol = note.category?.symbol {
                Image(systemName: symbol)
            }
            if let noteDate = note.date {
                Image(systemName: "calendar")
                Text(formatDate(noteDate))
            }
            if !locationString.isEmpty {
                Image(systemName: "mappin")
                Text(locationString)
            }
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.bottom, 3)
    }
    
    // MARK: - Helper Functions
    
    private var adjustedAttributedText: NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: note.attributedText)
        let newFontSize: CGFloat = 18
        let newTextColor: UIColor = .white
        
        mutable.enumerateAttributes(
            in: NSRange(location: 0, length: mutable.length),
            options: []
        ) { attributes, range, _ in
            var modified = attributes
            if let font = attributes[.font] as? UIFont {
                let newFont = UIFont(
                    descriptor: font.fontDescriptor,
                    size: newFontSize
                )
                modified[.font] = newFont
            } else {
                modified[.font] = UIFont.systemFont(ofSize: newFontSize)
            }
            modified[.foregroundColor] = newTextColor
            mutable.setAttributes(modified, range: range)
        }
        return mutable
    }
    
    private func reverseGeocodeIfNeeded() {
        if let loc = note.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(loc) { placemarks, error in
                if error == nil, let placemark = placemarks?.first {
                    locationString = placemark.locality ?? ""
                } else {
                    locationString = ""
                }
            }
        } else {
            locationString = ""
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        return dateFormatter.string(from: date)
    }
}
