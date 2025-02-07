//
//  PublicNoteView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 1/30/25.
//

import SwiftUI
import CoreLocation

/// Displays a single 'SupabaseNote', allowing a tap action.
/// This mimics the previous "PublicNoteView" structure but references
/// the fields on 'SupabaseNote'.
// MARK: - PublicNoteView

struct PublicNoteView: View {
    let note: SupabaseNote
    
    @State private var dynamicHeight: CGFloat = .zero
    @State private var locationString: String = ""
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    headerView
                    
                    // Renders the note's content as NSAttributedString
                    AttributedTextView(
                        attributedText: adjustedAttributedText,
                        dynamicHeight: $dynamicHeight
                    )
                    .frame(height: dynamicHeight)
                    
//                    footerView
                }
                Spacer()
            }
            .padding()
        }
        
        // To-do: add overlay
//        .overlay()
//        
        .background(backgroundColor)
        .cornerRadius(20)
        .padding(.vertical, 2)
        .listRowSeparator(.hidden)
        .foregroundColor(.stroke)
        .onAppear {
            reverseGeocodeIfNeeded()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        
        HStack {
            // Symbol from the note
            Image(systemName: note.symbol)
            
            Spacer()
            
            if let userName = note.profiles?.username {
                Text("@\(userName)")
            }
            
        }
        .font(.headline)
        .foregroundColor(.white)
    }
    

    // MARK: - Helper Computed Properties
    
    /// Converts plain text into an NSAttributedString.
    private var rawAttributedString: NSAttributedString {
        NSAttributedString(string: note.content)
    }
    
    /// Applies consistent font size/color to the note’s text.
    private var adjustedAttributedText: NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: rawAttributedString)
        let newFontSize: CGFloat = 18
        let newTextColor: UIColor = .white
        
        mutable.enumerateAttributes(in: NSRange(location: 0, length: mutable.length), options: []) { attributes, range, _ in
            var modified = attributes
            
            // Force a consistent font
            if let font = attributes[.font] as? UIFont {
                let newFont = UIFont(descriptor: font.fontDescriptor, size: newFontSize)
                modified[.font] = newFont
            } else {
                modified[.font] = UIFont.systemFont(ofSize: newFontSize)
            }
            
            // Force text color to white
            modified[.foregroundColor] = newTextColor
            mutable.setAttributes(modified, range: range)
        }
        return mutable
    }
    
    /// Converts `colorString` into a SwiftUI Color.
    private var backgroundColor: Color {
        switch note.colorString {
            case "green":  return .green
            case "blue":   return .blue
            case "yellow": return .yellow
            case "pink":   return .pink
            case "brown":  return .brown
            case "gray":   return .gray
            case "red":    return .red
            case "purple": return .purple
            case "orange": return .orange
            case "teal":   return .teal
            case "indigo": return .indigo
            default:       return .black
        }
    }
    
    /// Converts lat/lon into a CLLocation if present.
    private var location: CLLocation? {
        guard let lat = note.locationLatitude,
              let lon = note.locationLongitude else {
            return nil
        }
        return CLLocation(latitude: Double(lat), longitude: Double(lon))
    }
    
    // MARK: - Utility Methods
    
    private func reverseGeocodeIfNeeded() {
        guard let loc = location else {
            locationString = ""
            return
        }
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                locationString = placemark.locality ?? "Cambridge"
            } else {
                locationString = "Alabama"
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        return dateFormatter.string(from: date)
    }
}
