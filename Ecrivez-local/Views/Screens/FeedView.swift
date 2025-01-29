//
//  FeedView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/15/24.
//

import SwiftUI

struct FeedView: View {
    @State private var publicNotes: [PublicNote] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            if isLoading {
                
                ProgressView("Loading public notes...")
            } else if publicNotes.isEmpty {
                Text("No public notes found.")
            } else {
                List(publicNotes) { note in
                    Text(note.content)
                }
            }
        }
        .onAppear {
            Task { await loadPublicNotes() }
        }
    }
    
    private func loadPublicNotes() async {
        do {
            // Suppose your supabase table is "public_notes"
            // and the columns are: id (uuid), content(text), is_public(bool), user_id, etc.
            publicNotes = try await SupabaseManager.shared.client
                .from("notes")
                .select()
                .eq("shared", value: true)
                .execute()
                .value

        } catch {
            print("Error loading public notes: \(error)")
        }
        isLoading = false
    }
}

struct PublicNote: Identifiable, Codable {
    let id: String
    let content: String
    // add other fields as needed
}

//#Preview {
//    // Provide a sample array of notes
//    let sampleNotes = [
//        PublicNote(id: "1", content: "Public Note #1: Hello World"),
//        PublicNote(id: "2", content: "Public Note #2: Another idea"),
//        PublicNote(id: "3", content: "Public Note #3: Shared info")
//    ]
//
//    FeedView(publicNotes: sampleNotes)
//}
