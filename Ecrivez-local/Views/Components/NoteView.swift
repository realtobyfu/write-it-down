    //
    //  NoteView.swift
    //  Ecrivez-local
    //
    //  Created by Tobias Fu on 10/8/24.
    //
    import SwiftUI
    import UIKit
    import CoreLocation



    struct NoteView: View {
        let note: Note
        @Binding var selectedNote: Note?
        @Binding var showingNoteEditor: Bool
    //    @Binding var deleteMode: Bool
    //    var onDelete: (() -> Void)? = nil // Optional delete callback
        
        @State private var dynamicHeight: CGFloat = .zero

        @State private var locationString: String = "." // State to store the location string
        
        // Computed property to adjust the attributed text
        private var adjustedAttributedText: NSAttributedString {
            let mutableAttributedText = NSMutableAttributedString(attributedString: note.attributedText)
            let newFontSize: CGFloat = 18
            let newTextColor: UIColor = .white
            
            mutableAttributedText.enumerateAttributes(
                in: NSRange(location: 0, length: mutableAttributedText.length),
                options: []
            ) { attributes, range, _ in
                var modifiedAttributes = attributes
                
                if let font = attributes[.font] as? UIFont {
                    let fontDescriptor = font.fontDescriptor
                    let newFont = UIFont(descriptor: fontDescriptor, size: newFontSize)
                    modifiedAttributes[.font] = newFont
                } else {
                    modifiedAttributes[.font] = UIFont.systemFont(ofSize: newFontSize)
                }
                
                modifiedAttributes[.foregroundColor] = newTextColor
                mutableAttributedText.setAttributes(modifiedAttributes, range: range)
            }
            
            return mutableAttributedText
        }
        
        var body: some View {
            VStack {
                HStack {

                    
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: note.category!.symbol!)
                            Spacer(minLength: 5)
                            
                            if let noteDate = note.date {
                                Image(systemName: "calendar")
                                Text(formatDate(noteDate))
                            }
                            
                            if locationString != "" {
                                Image(systemName: "mappin") // Display the pin icon
                            }
                            // displays the location here
                            Text(locationString)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 3)
                        
                        AttributedTextView(attributedText: adjustedAttributedText, dynamicHeight: $dynamicHeight)
                            .frame(height: dynamicHeight) // Use the dynamically calculated height
                            .onTapGesture {
                                selectedNote = note
                                showingNoteEditor = true
                            }
                    }
                    Spacer()
                    
    //                if deleteMode {
    //                    Button(action: {
    //                        onDelete?()
    //                    }) {
    //                        Image(systemName: "minus.circle")
    //                            .foregroundColor(.red)
    //                    }
    //                }
                }
                .padding()
            }
            .onTapGesture {
                print("tapped")
                selectedNote = note
                showingNoteEditor = true
            }
            .background(note.category!.color)
            .cornerRadius(20)
            .padding(.vertical, 2)
            .listRowSeparator(.hidden)
            .foregroundColor(.white)
            .onAppear {
                // Reverse geocode location when the view appears
                if let location = note.location {
                    reverseGeocodeLocation(location)
                } else {
                    locationString = ""
                }
            }
        }
        
        private func reverseGeocodeLocation(_ location: CLLocation) {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print("Error reverse geocoding location: \(error)")
                    locationString = ""
                } else if let placemark = placemarks?.first {
                    // Only use the locality
                    locationString = placemark.locality ?? ""
                    print("Reverse geocoded location: \(locationString)") // Debugging
                } else {
                    locationString = ""
                    print("No placemark found")
                }
                // empty string if no location or unable to decode
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yy" // Format for MM/DD/YY
            return dateFormatter.string(from: date)
        }

    }
