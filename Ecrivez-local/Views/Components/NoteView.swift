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

    /// leaking too much info from the parent
    ///
//    @Binding var selectedNote: Note?
//  }
//    @Binding var showingNoteEditor: Bool
    
    let buttonTapped: () -> Void
    
    @State private var dynamicHeight: CGFloat = .zero
    @State private var locationString: String = ""
    
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
            if !locationString.isEmpty {
                Image(systemName: "mappin")
                    .foregroundColor(.white.opacity(0.9))
                Text(shortenedLocationString)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.bottom, 3)
    }

    // Computed property to handle location string length
    private var shortenedLocationString: String {
        // If location string is short enough, use it directly
        if locationString.count <= 12 {
            return locationString
        } else {
            // Otherwise, split by comma and take just the city name (typically first component)
            let components = locationString.components(separatedBy: ",")
            if let cityName = components.first?.trimmingCharacters(in: .whitespaces),
               !cityName.isEmpty {
                return cityName
            }
            // If no comma or city can be extracted, truncate the original
            return String(locationString.prefix(12))
        }
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
//    private func reverseGeocodeIfNeeded() {
//        if let loc = note.location {
//            let geocoder = CLGeocoder()
//            geocoder.reverseGeocodeLocation(loc) { placemarks, error in
//                if error == nil, let placemark = placemarks?.first {
//                    locationString = placemark.locality ?? ""
//                } else {
//                    locationString = ""
//                }
//            }
//        } else {
//            locationString = ""
//        }
//    }
//    
    private func reverseGeocodeIfNeeded() {
        if let loc = note.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(loc) { placemarks, error in
                if error == nil, let placemark = placemarks?.first {
                    // Try to get the most specific name first
                    if let name = placemark.name, !name.isEmpty {
                        locationString = name
                    } else if let locality = placemark.locality {
                        // City name
                        locationString = locality
                    } else if let area = placemark.administrativeArea {
                        // State/province
                        locationString = area
                    } else {
                        locationString = ""
                    }
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
