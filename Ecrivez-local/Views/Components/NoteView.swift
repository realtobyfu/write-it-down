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
    let foldAll: Bool
    let buttonTapped: () -> Void
    
    @State private var dynamicHeight: CGFloat = .zero
    
    var body: some View {
        // Wrap the entire cell in a Button
        Button {
            buttonTapped()
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
                        .frame(height: foldAll ? min(dynamicHeight, 100) : dynamicHeight, alignment: .top)
                        .clipped()
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
        }
        // Make the button look/act like a tap gesture (no default button styling)
        .buttonStyle(.plain)
        // Ensure the entire rectangle is the tap target
        .contentShape(Rectangle())
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        HStack {
            // Category icon
            if let symbol = note.category?.symbol {
                Image(systemName: symbol)
            }
            
            Spacer()
            
            // Date (if present)
            if let noteDate = note.date {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.9))
                Text(formatDate(noteDate))
                    .lineLimit(1)
            }
            
            // Location (if present)
            if let location = getLocationDisplayName(), !location.isEmpty {
                Image(systemName: "mappin")
                    .foregroundColor(.white.opacity(0.9))
                Text(location)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.bottom, 3)
    }

    // Get the display name based on the rules (landmark < 12 chars, else locality)
    private func getLocationDisplayName() -> String? {
        if let name = note.locationName, !name.isEmpty, name.count < 12 {
            return name
        } else if let locality = note.locationLocality, !locality.isEmpty {
            return locality
        } else if let name = note.locationName, !name.isEmpty {
            // Fallback to locationName even if > 12 chars
            return name
        }
        return nil
    }
    
    // MARK: - Helper Functions
    private var adjustedAttributedText: NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: note.attributedText)
        
        let maxFontSize: CGFloat = 22
        let newTextColor: UIColor = .white

        mutable.enumerateAttributes(
            in: NSRange(location: 0, length: mutable.length),
            options: []
        ) { attributes, range, _ in
            var modified = attributes
            
            if let font = attributes[.font] as? UIFont {
                let clampedSize = min(font.pointSize, maxFontSize)
                let newFont = UIFont(
                    descriptor: font.fontDescriptor,
                    size: clampedSize
                )
                modified[.font] = newFont
            } else {
                modified[.font] = UIFont.systemFont(ofSize: maxFontSize)
            }
            
            modified[.foregroundColor] = newTextColor
            mutable.setAttributes(modified, range: range)
        }
        
        return mutable
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        return dateFormatter.string(from: date)
    }
}
