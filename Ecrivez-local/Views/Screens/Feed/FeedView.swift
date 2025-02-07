//
//  FeedView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/15/24.
//

import SwiftUI
import CoreLocation

// MARK: - FeedView

struct FeedView: View {
    @State private var publicNotes: [SupabaseNote] = []
    @State private var isLoading = true
    
    let isAuthenticated: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading public notes...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if publicNotes.isEmpty {
                    Text("No public notes found.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(publicNotes) { note in
                        NavigationLink {
                            PublicNoteDetailView(note: note, isAuthenticated: isAuthenticated)
                        } label: {
                            PublicNoteView(note: note)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .onAppear {
                Task {
                    await loadPublicNotes()
                }
            }
            .overlay(
                Button(action: {
                    dismiss()  // dismiss FeedView
                }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(30),
                alignment: .bottomLeading
    
            )
        }
//        .navigationTitle("Public Feed")

    }
    
    private func loadPublicNotes() async {
        do {
            // Suppose your Supabase table is "public_notes"
            // and the columns are: id (uuid), content(text), date, etc.
            publicNotes = try await SupabaseManager.shared.client
                .from("public_notes")
                .select("id, owner_id, category_id, content, date, locationLongitude, locationLatitude, colorString, symbol, profiles (username)")
                .execute()
                .value
        } catch {
            print("Error loading public notes: \(error)")
        }
        isLoading = false
        
        print("Retrieved notes from database: \(publicNotes)")
    }
}

