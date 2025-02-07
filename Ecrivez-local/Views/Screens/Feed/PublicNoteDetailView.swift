//
//  PublicNoteDetailView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/5/25.
//

// MARK: - PublicNoteDetailView

import SwiftUI
import CoreLocation

struct PublicNoteDetailView: View {
    let note: SupabaseNote
    let isAuthenticated: Bool
    
    
    @State private var locationString: String = ""

    // MARK: - Like State
    @State private var hasLiked = false
    @State private var likeCount = 0
    
    // For a quick "pop" animation on tap:
    @State private var animateLike = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // The note content (plain text for now)
                    Text(note.content)
                        .font(.body)
                        .padding()
                    
                    // Additional details (e.g. date)
                    if let date = note.date {
                        Text("Date: \(date, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }

                    // Show like count separately
                    Text("Likes: \(likeCount)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(backgroundColor)
            .cornerRadius(20)

            .listRowSeparator(.hidden)
            .foregroundColor(.stroke)
            .onAppear {
                reverseGeocodeIfNeeded()
            }

            .navigationTitle("Note Detail")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Overlay: Like & DM Buttons
            VStack {
                Spacer()
                HStack {
                    VStack (spacing: 5) {
                        // MARK: DM Button (bottom-right)
                        if isAuthenticated {
                            
                            HStack(spacing: 5) {
                                Button(action: {
                                    print("DM button tapped!")
                                    // Insert your DM logic here
                                }) {
                                    Image(systemName: "paperplane.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(
                                            Circle()
                                                .fill(Color.brown)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                                .shadow(radius: 4)
                                        )
                                    Text("message")
                                        .padding(.leading, 8)
                                        .foregroundStyle(.stroke)
                                }
                                
                            }
                            .padding(.bottom, 10)
                        }
                        
                        
                        HStack(spacing: 5){
                            
                            // MARK: Like Button (bottom-left)
                            Button(action: toggleLike) {
                                // Heart icon + pop animation
                                Image(systemName: hasLiked ? "heart.fill" : "heart")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(hasLiked ? .red : .blue)
                                    .scaleEffect(animateLike ? 1.2 : 1.0)
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .overlay(
                                                Circle()
                                                    .stroke(hasLiked ? .red : .blue, lineWidth: 2)
                                            )
                                            .shadow(radius: hasLiked ? 0 : 4)
                                    )
                            }
                            Text("like")
                                .foregroundStyle(.stroke)
                                .padding(.leading, 8)
                        }
                        
                        
                    }
                    .padding(.leading, 30)
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            // (Placeholder) Load the current like state from DB
            Task {
                await loadLikeState()
            }
        }
    }
    
    // MARK: - Date Formatter
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }
    
    // MARK: - Like Logic
    private func loadLikeState() async {
        // Placeholder for your Supabase or other DB logic.
        // For example:
        // 1. Check if the current user has liked this note (set hasLiked accordingly).
        // 2. Fetch total like count for the note.
        
        // Example dummy data (remove in production):
        hasLiked = false
        likeCount = Int.random(in: 0...100)
    }
    
    private func toggleLike() {
        // Instantly reflect UI changes
        hasLiked.toggle()
        
        // Scale up for a quick pop
        animateLike = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring()) {
                animateLike = false
            }
        }
        
        // Adjust local likeCount
        likeCount += hasLiked ? 1 : -1

        // Then do your actual update in Supabase or wherever:
        // e.g. insert into "note_likes" or remove from it, etc.
        Task {
            await updateDatabaseLike()
        }
    }

    private func updateDatabaseLike() async {
        // Placeholder: your actual DB logic goes here.
        // If hasLiked == true => Insert row
        // If hasLiked == false => Delete row
        //
        // i.e. something like:
        // do {
        //   let user = try await SupabaseManager.shared.client.auth.user()
        //   let userID = user.id
        //   if hasLiked {
        //     try await SupabaseManager.shared.client
        //       .from("note_likes")
        //       .insert(["note_id": note.id, "user_id": userID])
        //       .execute()
        //   } else {
        //     try await SupabaseManager.shared.client
        //       .from("note_likes")
        //       .delete()
        //       .eq("note_id", note.id)
        //       .eq("user_id", userID)
        //       .execute()
        //   }
        // } catch {
        //   print("Error toggling like: \(error)")
        // }
    }
}

extension PublicNoteDetailView {
    private var headerView: some View {
        HStack {
            // Symbol
            Image(systemName: note.symbol)
            
            Spacer()
            
            // Date if present
            if let date = note.date {
                Image(systemName: "calendar")
                Text(formatDate(date))
            }
            
            // Location if present
            if !locationString.isEmpty {
                Image(systemName: "mappin")
                Text(locationString)
            }
        }
        .font(.headline)
        .foregroundColor(.white)
    }
    
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yy"
        return df.string(from: date)
    }
    
    /// Convert colorString -> SwiftUI Color
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

    /// Reverse geocode location if lat/lon exist
    private func reverseGeocodeIfNeeded() {
        guard let lat = note.locationLatitude, let lon = note.locationLongitude else {
            locationString = ""
            return
        }
        let location = CLLocation(latitude: Double(lat), longitude: Double(lon))
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                let locality = placemark.locality ?? ""
                // Only show the location if non-empty
                if !locality.isEmpty {
                    locationString = locality
                }
            }
        }
    }

}
