//
//  PublicNoteView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 1/30/25.
//

import SwiftUI
import CoreLocation

struct PublicNoteView: View {
    let note: SupabaseNote
    
    @State private var dynamicHeight: CGFloat = .zero
    @State private var locationString: String = ""

    var body: some View {
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
        .background(backgroundColor)
        .cornerRadius(20)
        .padding(.vertical, 2)
        .listRowSeparator(.hidden)
        .foregroundColor(.white)
        .onAppear {
            reverseGeocodeIfNeeded()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            // Symbol
            Image(systemName: note.symbol)
            
            Spacer()
            
            // If anonymous or user’s username
            if note.isAnnonymous == true {
                Text("Anonymous")
            } else if let userName = note.profiles?.username {
                Text("@\(userName)")
            }

            // Show location if found
            if !locationString.isEmpty {
                Image(systemName: "mappin")
                Text(locationString)
            }
        }
        .font(.headline)
    }
    
    // MARK: - Decoding the RTF
    private var rawAttributedString: NSAttributedString {
        if let base64RTF = note.rtf_content,
           let data = Data(base64Encoded: base64RTF) {
            do {
                return try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
            } catch {
                print("Error decoding RTF: \(error)")
                return NSAttributedString(string: note.content) // fallback
            }
        } else {
            return NSAttributedString(string: note.content)
        }
    }
    
    private var adjustedAttributedText: NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: rawAttributedString)
        let newFontSize: CGFloat = 18
        let newTextColor: UIColor = .white
        
        mutable.enumerateAttributes(
            in: NSRange(location: 0, length: mutable.length),
            options: []
        ) { attributes, range, _ in
            var modified = attributes
            if let font = attributes[.font] as? UIFont {
                let newFont = UIFont(descriptor: font.fontDescriptor, size: newFontSize)
                modified[.font] = newFont
            } else {
                modified[.font] = UIFont.systemFont(ofSize: newFontSize)
            }
            // Force the text color to white
            modified[.foregroundColor] = newTextColor
            mutable.setAttributes(modified, range: range)
        }
        return mutable
    }
    
    // MARK: - Reverse Geocoding
    private func reverseGeocodeIfNeeded() {
        // Check the computed property `note.location` from your SupabaseNote extension
        guard let loc = note.location else {
            locationString = ""
            return
        }
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
            guard error == nil, let place = placemarks?.first else {
                print("Cannot find the exact location names")
                locationString = ""
                return
            }
            
            print("reverse geo coded: \(place)")
            // For example, just store the city/locality
            locationString = place.locality ?? ""
        }
    }

    private var backgroundColor: Color {
        switch note.colorString {
            case "green":   return .green
            case "blue":    return .blue
            case "yellow":  return .yellow
            case "pink":    return .pink
            case "brown":   return .brown
            case "gray":    return .gray
            case "red":     return .red
            case "purple":  return .purple
            case "orange":  return .orange
            case "teal":    return .teal
            case "indigo":  return .indigo
            default:        return .black
        }
    }
}
