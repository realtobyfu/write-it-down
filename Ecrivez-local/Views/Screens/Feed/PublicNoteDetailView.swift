import SwiftUI
import CoreLocation

struct PublicNoteDetailView: View {
    let note: SupabaseNote
    let isAuthenticated: Bool
    let currentUserID: UUID?
    
    @State private var locationString: String = ""
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode

    // MARK: - State Variables
    @State private var hasLiked = false
    @State private var likeCount = 0
    @State private var animateLike = false
    @State private var commentText = ""
    @State private var showingComments = false
    @State private var showingAuthView = false
    
    @State private var comments: [CommentModel] = []
    @State private var isLoadingComments = false
    @State private var showCommentError = false
    @State private var errorMessage = ""
    
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
                        .padding(.horizontal)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
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
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                }
                .padding()
                .background(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? Color.blue.opacity(0.2) : Color.black.opacity(0.1),
                       radius: colorScheme == .dark ? 8 : 5,
                       x: 0,
                       y: colorScheme == .dark ? 2 : 1)
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
        .sheet(isPresented: $showingAuthView) {
            AuthenticationView(authVM: AuthViewModel())
        }
    }
    
    // MARK: - Note Header
    private var noteHeader: some View {
        HStack(spacing: 16) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 50) {
                if note.isAnnonymous == true {
                    Text("anonymous")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                } else if let userName = note.profiles?.username {
                    HStack(spacing: 0) {
                        Text("@")
                            .font(.headline)
                        Text("\(userName)")
                            .font(.custom("Baskerville", size: 25))
                            .italic()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                } else {
                    Text("User")
                        .font(.custom("Baskerville", size: 25))
                        .italic()
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }

            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 50, height: 50)
                
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
            // Like Button with counter horizontally aligned
            Button(action: {
                if isAuthenticated {
                    toggleLike()
                } else {
                    // Redirect to auth view if not authenticated
                    showingAuthView = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: hasLiked ? "heart.fill" : "heart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(hasLiked ? .red : (colorScheme == .dark ? .white : .gray))
                        .scaleEffect(animateLike ? 1.2 : 1.0)
                    
                    if likeCount > 0 {
                        Text("\(likeCount)")
                            .font(.subheadline)
                            .foregroundColor(hasLiked ? .red : (colorScheme == .dark ? .white : .gray))
                    }
                }
            }
            .buttonStyle(StaticButtonStyle())
            
            // Comment Button with counter horizontally aligned
            Button {
                withAnimation {
                    showingComments.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showingComments ? "bubble.left.fill" : "bubble.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(showingComments ? .blue : (colorScheme == .dark ? .white : .gray))
                    
                    if comments.count > 0 {
                        Text("\(comments.count)")
                            .font(.subheadline)
                            .foregroundColor(showingComments ? .blue : (colorScheme == .dark ? .white : .gray))
                    }
                }
            }
            .buttonStyle(StaticButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.blue.opacity(0.2) : Color.black.opacity(0.05),
               radius: colorScheme == .dark ? 8 : 5,
               x: 0,
               y: colorScheme == .dark ? 2 : 1)
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
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            // New Comment Entry
            if isAuthenticated {
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
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
            } else {
                Button("Sign in to comment") {
                    showingAuthView = true
                }
                .buttonStyle(.bordered)
                .padding(.vertical)
            }
            
            // Comments List
            if isLoadingComments {
                ProgressView("Loading comments...")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.top)
            } else if comments.isEmpty {
                Text("No comments yet")
                    .italic()
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    .padding(.top)
            } else {
                ForEach(comments) { comment in
                    CommentView(comment: comment, colorScheme: colorScheme)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.blue.opacity(0.2) : Color.black.opacity(0.1),
               radius: colorScheme == .dark ? 8 : 5,
               x: 0,
               y: colorScheme == .dark ? 2 : 1)
        .alert(isPresented: $showCommentError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Comment View
    struct CommentView: View {
        let comment: CommentModel
        let colorScheme: ColorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 0) {
                            Text("@")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)

                            Text("\(comment.profiles?.username ?? "User")")
                                .font(.custom("Baskerville", size: 18))
                                .italic()
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }

                        // Simplified timestamp format
                        Text(formattedTimestamp(for: comment.created_at ?? Date()))
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    }
                }
                
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
            }
            .padding(.vertical, 4)
        }
        
        // Helper to format timestamp as requested
        private func formattedTimestamp(for date: Date) -> String {
            let now = Date()
            let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
            
            if let minutes = components.minute, minutes < 60 {
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
            
            // Check if the current user has liked this note (only if authenticated)
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
        // Only perform optimistic UI update if authenticated
        if isAuthenticated {
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
    }
    
    private func updateDatabaseLike() async {
        do {
            try await NoteRepository.shared.toggleLike(noteID: note.id)
            
            // Refresh like state to ensure UI is correct
            await loadLikeState()
        } catch {
            print("Error toggling like: \(error)")
            // Restore previous state if there was an error
            await loadLikeState()
        }
    }
    
    private func loadComments() async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        
        do {
            comments = try await NoteRepository.shared.fetchComments(noteID: note.id)
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
            showCommentError = true
        }
    }
    
    private func postComment() async {
        guard !commentText.isEmpty else { return }
        
        do {
            try await NoteRepository.shared.addComment(noteID: note.id, content: commentText)
            
            // Refresh comments
            await loadComments()
            
            // Clear the input field
            commentText = ""
        } catch {
            errorMessage = "Failed to post comment: \(error.localizedDescription)"
            showCommentError = true
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
                    locationString = locality
                }
            }
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
