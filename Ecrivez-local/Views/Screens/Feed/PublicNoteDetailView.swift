//
//  PublicNoteDetailView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/5/25.
//  Redesigned with improved UI and comment functionality
//

import SwiftUI
import CoreLocation

struct PublicNoteDetailView: View {
    
    let note: SupabaseNote
    let isAuthenticated: Bool
    let currentUserID: UUID?
    
    @State private var locationString: String = ""
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State Variables
    @State private var hasLiked = false
    @State private var likeCount = 0
    @State private var animateLike = false
    @State private var commentText = ""
    @State private var showingComments = false
    
    // Sample comments for UI preview
    @State private var comments: [CommentModel] = []
    @State private var isLoadingComments = false
    @State private var showAddCommentError = false
    @State private var errorMessage = ""

    struct CommentPreview: Identifiable {
        let id = UUID()
        let username: String
        let text: String
        let timestamp: Date
    }
    
    // MARK: - Computed Properties for Dark Mode
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Combined Header & Content
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    noteHeader
                    
                    // Note content
                    Text(note.content)
                        .font(.body)
                        .foregroundColor(textColor)
                        .padding(.horizontal)
                    
                    // MARK: - Metadata
                    HStack(spacing: 16) {
                        
                        Spacer()

                        // Date
                        if let date = note.date {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(formatDate(date))
                                    .font(.caption)
                            }
                        }
                        
                        // Location
                        if !locationString.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.caption)
                                Text(locationString)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .foregroundColor(secondaryTextColor)
                }
                .padding()
                .background(cardBackgroundColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 5)
                .padding()
                
                // MARK: - Actions Bar
                actionsBar
                    .padding(.horizontal)
                
                // MARK: - Comments Section
                if showingComments {
                    commentsSection
                        .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            reverseGeocodeIfNeeded()
            Task {
                await loadLikeState()
                await loadComments()
            }
        }
    }
    
    // MARK: - Note Header
    private var noteHeader: some View {
        HStack(spacing: 16) {
            // Category Icon
            Spacer()

            VStack(alignment: .leading, spacing: 50) {
                // Author info
                
                if note.isAnonymous ?? false {
                    Text("Anonymous")
                        .font(.custom("Baskerville", size: 25))
                        .italic()
                } else if let userName = note.profiles?.username {
                    HStack(spacing: 0) {
                        Text("@")
                            .font(.headline)
                        Text("\(userName)")
                            .font(.custom("Baskerville", size: 25))
                            .italic()
                    }
                    .foregroundColor(textColor)
                } else {
                    // Fallback if both conditions fail
                    Text("User")
                        .font(.custom("Baskerville", size: 25))
                        .italic()
                        .foregroundColor(textColor)
                }
            }

            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
                
                Image(systemName: note.symbol)
                    .font(.title2)
                    .foregroundColor(.white)
            }

        }
        .padding(.bottom, 0)
    }
    
    // MARK: - Actions Bar
    private var actionsBar: some View {
        HStack(spacing: 60) {
            // Like Button with counter
            HStack(spacing: 10) {
                Button(action: toggleLike) {
                    Image(systemName: hasLiked ? "heart.fill" : "heart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(hasLiked ? .red : (colorScheme == .dark ? .gray : .gray))
                        .scaleEffect(animateLike ? 1.2 : 1.0)
                }
                .buttonStyle(StaticButtonStyle())
                
                if likeCount > 0 {
//                    print(likeCount)
                    Text("\(likeCount)")
                        .font(.caption)
                        .foregroundColor(hasLiked ? .red : (colorScheme == .dark ? .gray : .gray))
                }
            }
            .padding(.leading, 4)
            .frame(width: 50, height: 50, alignment: .leading) // Fixed height to prevent movement
            
            // Comment Button with counter
            HStack(spacing: 10) {
                Button {
                    withAnimation {
                        showingComments.toggle()
                    }
                } label: {
                    Image(systemName: showingComments ? "bubble.left.fill" : "bubble.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(showingComments ? .blue : (colorScheme == .dark ? .gray : .gray))
                }
                .buttonStyle(StaticButtonStyle())
                
                if comments.count > 0 {
                    Text("\(comments.count)")
                        .font(.caption)
                        .foregroundColor(showingComments ? .blue : (colorScheme == .dark ? .gray : .gray))
                }
            }
            .frame(height: 50, alignment: .leading) // Fixed height to prevent movement
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5)
    }
    
    // Custom button style to prevent movement when pressed
    struct StaticButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                // No transformations when pressed
        }
    }
    
    // MARK: - Comments Section
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments")
                .font(.headline)
                .foregroundColor(textColor)
            
            // New Comment Entry
            if isAuthenticated {
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        if !commentText.isEmpty {
                            Task {
                                await postComment()
                            }
                        }
                    } label: {
                        Text("Post")
                    }
                    .buttonStyle(.bordered)
                    .disabled(commentText.isEmpty)
                }
            }
            
            // Comments List
            if isLoadingComments {
                ProgressView("Loading comments...")
            } else if comments.isEmpty {
                Text("No comments yet")
                    .italic()
                    .foregroundColor(secondaryTextColor)
                    .padding(.top)
            } else {
                ForEach(comments) { comment in
                    CommentRowView(
                        comment: comment,
                        isOwner: comment.user_id == currentUserID,
                        onDelete: {
                            Task {
                                await deleteComment(commentID: comment.id)
                            }
                        },
                        onEdit: { newContent in
                            Task {
                                await editComment(commentID: comment.id, newContent: newContent)
                            }
                        }
                    )
                    .environment(\.colorScheme, colorScheme)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1), radius: 5)
        .alert(isPresented: $showAddCommentError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Comment View
    struct CommentView: View {
        let comment: CommentPreview
        @Environment(\.colorScheme) private var colorScheme
        
        private var textColor: Color {
            colorScheme == .dark ? Color.white : Color.black
        }
        
        private var secondaryTextColor: Color {
            colorScheme == .dark ? Color.gray : Color.secondary
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 0) {
                            Text("@")
                                .font(.subheadline)
                                .foregroundColor(textColor)

                            Text("\(comment.username)")
                                .font(.custom("Baskerville", size: 18))
                                .italic()
                                .foregroundColor(textColor)
                        }

                        // Simplified timestamp format
                        Text(formattedTimestamp(for: comment.timestamp))
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                }
                
                Text(comment.text)
                    .font(.body)
                    .foregroundColor(textColor)
                
                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.2))
            }
            .padding(.vertical, 4)
        }
        
        // Helper to format timestamp as requested
        private func formattedTimestamp(for date: Date) -> String {
            let now = Date()
            let components = Calendar.current.dateComponents([.second, .minute, .hour, .day], from: date, to: now)
            
            // Show just one time indicator (minutes, hours, or days)
            if let seconds = components.second, seconds < 60 {
                return "Now"
            } else if let minutes = components.minute, minutes < 60 {
                return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
            } else if let hours = components.hour, hours < 24 {
                return "\(hours) hour\(hours == 1 ? "" : "s") ago"
            } else if let days = components.day, days == 1 {
                return "Yesterday"
            } else if let days = components.day, days < 7 {
                return "\(days) day\(days == 1 ? "" : "s") ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: date)
    }
    
    private func loadLikeState() async {
        do {
            // Get the current like count
            likeCount = try await NoteRepository.shared.fetchLikeCount(noteID: note.id)
            
            // Check if the current user has liked this note
            if isAuthenticated {
                hasLiked = await NoteRepository.shared.checkUserLikedNote(noteID: note.id)
            } else {
                hasLiked = false
            }
        } catch {
            print("Error loading like state: \(error)")
        }
    }
    
    private func toggleLike() {
        hasLiked.toggle()
        likeCount += hasLiked ? 1 : -1
        
        animateLike = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring()) {
                animateLike = false
            }
        }
        
        Task {
            await updateDatabaseLike()
        }
    }
    
    private func updateDatabaseLike() async {
        do {
            guard isAuthenticated else {
                // Handle unauthenticated user
                return
            }
            
            try await NoteRepository.shared.toggleLike(noteID: note.id)
        } catch {
            // Handle error (perhaps show an alert)
            print("Error toggling like: \(error)")
        }
    }
    
    private func postComment() async {
        guard !commentText.isEmpty else { return }
        
        do {
            // Add the comment to the database
            try await NoteRepository.shared.addComment(noteID: note.id, content: commentText)
            
            // Refresh comments
            await loadComments()
            
            // Clear the input field
            commentText = ""
        } catch {
            errorMessage = "Failed to post comment: \(error.localizedDescription)"
            showAddCommentError = true
        }
    }

    private func loadComments() async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        
        do {
            comments = try await NoteRepository.shared.fetchComments(noteID: note.id)
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
            showAddCommentError = true
        }
    }
    
    private func deleteComment(commentID: UUID) async {
        do {
            try await NoteRepository.shared.deleteComment(commentID: commentID)
            await loadComments()
        } catch {
            errorMessage = "Failed to delete comment: \(error.localizedDescription)"
            showAddCommentError = true
        }
    }

    private func editComment(commentID: UUID, newContent: String) async {
        do {
            try await NoteRepository.shared.updateComment(commentID: commentID, newContent: newContent)
            await loadComments()
        } catch {
            errorMessage = "Failed to update comment: \(error.localizedDescription)"
            showAddCommentError = true
        }
    }
    
    private func reverseGeocodeIfNeeded() {
        guard let lat = note.locationLatitude, let lon = note.locationLongitude else {
            locationString = ""
            return
        }
        let location = CLLocation(latitude: Double(lat)!, longitude: Double(lon)!)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                let locality = placemark.locality ?? ""
                if !locality.isEmpty {
                    DispatchQueue.main.async {
                        locationString = locality
                    }
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        return StyleManager.color(from: note.colorString)
    }
}

//// MARK: - Preview
//#Preview {
//    Group {
//        NavigationStack {
//            PublicNoteDetailView(
//                note: SupabaseNote(
//                    id: UUID(),
//                    owner_id: UUID(),
//                    category_id: UUID(),
//                    content: "This is a sample note with some interesting content that talks about various things. It could be a longer text with multiple paragraphs and ideas that the user has shared with the community.\n\nThe design now shows sample comments and improved button layout with counters.",
//                    rtf_content: nil,
//                    date: Date(),
//                    locationName: "Twitter, Inc.", locationLocality: "San Francisco",
//                    locationLatitude: "37.7749",
//                    locationLongitude: "-122.4194",
//                    colorString: "blue",
//                    symbol: "book.fill",
//                    isAnnonymous: false
//                ),
//                isAuthenticated: true,
//                currentUserID: UUID()
//            )
//            .preferredColorScheme(.light)
//        }
//        
//        NavigationStack {
//            PublicNoteDetailView(
//                note: SupabaseNote(
//                    id: UUID(),
//                    owner_id: UUID(),
//                    category_id: UUID(),
//                    content: "This is a sample note with some interesting content that talks about various things. It could be a longer text with multiple paragraphs and ideas that the user has shared with the community.\n\nThe design now shows sample comments and improved button layout with counters.",
//                    rtf_content: nil,
//                    date: Date(),
//                    locationName: "Twitter, Inc.", locationLocality: "San Francisco",
//                    locationLatitude: "37.7749",
//                    locationLongitude: "-122.4194",
//                    colorString: "blue",
//                    symbol: "book.fill",
//                    isAnnonymous: false
//                ),
//                isAuthenticated: true,
//                currentUserID: UUID()
//            )
//            .preferredColorScheme(.dark)
//        }
//    }
//}
