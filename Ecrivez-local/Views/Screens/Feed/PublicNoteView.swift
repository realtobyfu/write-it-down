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
    @Environment(\.colorScheme) private var colorScheme
    
    // Text colors based on color scheme
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with icon and username
                    HStack {
                        ZStack {
                            Circle()
                                .fill(cardBackgroundColor)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: note.symbol)
                                .foregroundColor(backgroundColor)
                                .font(.system(size: 18))
                        }
                        
                        Spacer()
                        
                        // If anonymous or user's username
                        HStack {
                            if note.isAnonymous == true {
//                                Text("Anonymous")
//                                    .font(.subheadline)
//                                    .foregroundColor(secondaryTextColor)
                            } else if let userName = note.profiles?.username {
                                HStack(spacing: 0) {
                                    Text("@")
                                        .font(.subheadline)
                                    Text(userName)
                                        .font(.custom("Baskerville", size: 16))
                                        .italic()
                                }
                                .foregroundColor(secondaryTextColor)
                            }
                        }
                        
                        // Location if available
                        if !locationString.isEmpty {
                            Image(systemName: "mappin")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                            Text(locationString)
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    
                    // Note content
                    Text(note.content)
                        .font(.body)
                        .foregroundColor(textColor)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Date if available
                    if let date = note.date {
                        HStack {
                            Spacer()
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(formatDate(date))
                                .font(.caption)
                        }
                        .foregroundColor(secondaryTextColor)
                    }
                }
                Spacer()
            }
            .padding()
        }
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(backgroundColor, lineWidth: 2)
        )
        .shadow(radius: 2)
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .listRowSeparator(.hidden)
        .onAppear {
            reverseGeocodeIfNeeded()
        }
    }
    
    // Keep your existing helper functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func reverseGeocodeIfNeeded() {
        guard let loc = note.location else {
            locationString = ""
            return
        }
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
            guard error == nil, let place = placemarks?.first else {
                locationString = ""
                return
            }
            
            locationString = place.locality ?? ""
        }
    }

    private var backgroundColor: Color {
        return StyleManager.color(from: note.colorString)
    }
}
