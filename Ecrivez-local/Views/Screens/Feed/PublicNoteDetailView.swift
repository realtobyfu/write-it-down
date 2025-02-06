//
//  PublicNoteDetailView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/5/25.
//

// MARK: - PublicNoteDetailView

import SwiftUI

struct PublicNoteDetailView: View {
    let note: SupabaseNote
    let isAuthenticated: Bool

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
            .navigationTitle("Note Detail")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Overlay: Like & DM Buttons
            VStack {
                Spacer()
                HStack {
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
                    .padding(.leading, 30)
                    
                    Spacer()
                    
                    // MARK: DM Button (bottom-right)
                    if isAuthenticated {
                        Button(action: {
                            print("DM button tapped!")
                            // Insert your DM logic here
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                Text("DM")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(Color.brown)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(radius: 4)
                            )
                        }
                        .padding(.trailing, 30)
                    }
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
