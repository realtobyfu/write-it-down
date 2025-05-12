import SwiftUI
import _PhotosUI_SwiftUI
import Storage
import CoreData
import UIKit
import PhotosUI

struct ProfileView: View {
    
    @ObservedObject var authVM: AuthViewModel
    
    @State private var isEditing = false
    
    // The user's profile that we're displaying or editing
    @State var editedProfile: Profile
    
    // For picking a new profile photo
    @State private var selectedImageData: Data?
    @State private var selectedImageItem: PhotosPickerItem?  // Add this back
    
    // For camera selection
    @State private var isShowingCameraPicker = false
    @State private var isConfirmationDialogPresented = false
    
    // For error / saving state
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var isUploading = false

    // MARK: - MyPublicNotes states
    @Environment(\.managedObjectContext) private var context
    @State private var myNotes: [SupabaseNote] = []
    @State private var isLoadingMyNotes = false
    
    // Optional to open local note in a sheet
    @State private var selectedLocalNote: Note?
    @State private var showingNoteEditor = false
    
    // Add a loading state
    @State private var isLoadingEditor = false

    // Pre-fetch categories in onAppear rather than during sheet presentation
    @State private var cachedCategories: [Category] = []

    // Add state for showing authentication view
    @State private var showingAuthView = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with profile photo and name
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 180)
                    
                    VStack(spacing: 12) {
                profilePhotoSection
                            .shadow(radius: 4)
                        
                        if !isEditing {
                            Text(editedProfile.display_name ?? "Display Name")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            
                            Text("@\(editedProfile.username ?? "username")")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.top, 20)
                }
                
                // Main content area
                VStack(spacing: 24) {
                    // Edit form or Action buttons
                    if isEditing {
                        editingFields
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    } else {
                        HStack(spacing: 16) {
                            Button(action: { isEditing = true }) {
                                Label("Edit Profile", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: { authVM.signOut() }) {
                                Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .frame(maxWidth: .infinity)
                    }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 16)
                }
                    
                    // Error message
                if let errorMessage {
                    Text(errorMessage)
                            .font(.caption)
                        .foregroundColor(.red)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                    // Data Sync section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Synchronization")
                            .font(.headline)
                            .padding(.horizontal)
                        
                    if authVM.isAuthenticated {
                        SyncControlView()
                            .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                            Text("Sign in to enable syncing across devices")
                                .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            
                                Button(action: {
                                    // Present the authentication view
                                    showingAuthView = true
                                }) {
                                    Label("Sign In", systemImage: "person.fill.badge.plus")
                                        .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                    }
                }
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    
                    // My Public Notes section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                    Text("My Public Notes")
                        .font(.headline)
                            
                            Spacer()
                            
                            if !myNotes.isEmpty {
                                Text("\(myNotes.count) notes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    
                    if isLoadingMyNotes {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                    } else if myNotes.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray.opacity(0.7))
                        Text("No public notes found.")
                            .foregroundColor(.gray)
                                }
                                .padding()
                                Spacer()
                            }
                    } else {
                            // Card-style notes list
                            VStack(spacing: 10) {
                        ForEach(myNotes) { supaNote in
                                    buildNoteCard(for: supaNote)
                                }
                        }
                    }
                }
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
            }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { 
                try await loadMyPublicNotes() 
                cachedCategories = await fetchCategoriesAsync()
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            if let note = selectedLocalNote {
                NoteEditorView(
                    mode: .edit(note),
                    categories: cachedCategories, context: context,
                    isAuthenticated: authVM.isAuthenticated,
                    onSave: {
                        Task {
                            try await loadMyPublicNotes()
                        }
                    }
                )
            }
        }
        // Present authentication sheet when showingAuthView is true
        .sheet(isPresented: $showingAuthView) {
            AuthenticationView(authVM: authVM)
        }
    }
    
    // MARK: - Profile Photo
    @ViewBuilder
    var profilePhotoSection: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 100, height: 100)
            
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundColor(.blue)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
            
            if isEditing {
                Button(action: { isConfirmationDialogPresented = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 35, y: 35)
            }
        }
    }
    
    // MARK: - Editing Fields
    @ViewBuilder
    var editingFields: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "at")
                        .foregroundColor(.secondary)
                    
                    TextField("Username", text: $editedProfile.username.orEmpty)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.secondary)
                    
                    TextField("Display Name", text: $editedProfile.display_name.orEmpty)
                }
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                Button(action: { cancelEditing() }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isSaving || isUploading)
                
                Button(action: { Task { await saveProfileEdits() } }) {
                    if isSaving || isUploading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save")
                    }
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isSaving || isUploading)
            }
        }
    }
    
    // MARK: - Note Card
    @ViewBuilder
    func buildNoteCard(for supaNote: SupabaseNote) -> some View {
        let localNote = fetchLocalNote(with: supaNote.id)
        
        VStack(alignment: .leading, spacing: 12) {
            // Content preview
            Text(supaNote.content.prefix(40) + (supaNote.content.count > 40 ? "..." : ""))
                .lineLimit(2)
                .font(.body)
            
            // Date and action buttons
            HStack {
//                if let date = supaNote.created_at {
//                    Text(date, style: .date)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                
                Spacer()
                
                if localNote != nil {
                    Button(action: {
                        selectedLocalNote = localNote
                        showingNoteEditor = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Button(action: {
                    Task { try await NoteRepository.shared.deletePublicNote(supaNote.id) }
                }) {
                    Label("Delete", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Load Public Notes
    private func loadMyPublicNotes() async throws {
        isLoadingMyNotes = true
        defer { isLoadingMyNotes = false }
        
        do {
            myNotes = try await NoteRepository.shared.fetchMyPublicNotes()
        } catch {
            errorMessage = "Error loading notes: \(error.localizedDescription)"
        }
    }
}

// MARK: - Subviews & Helpers
extension ProfileView {
    
    @MainActor
    private func fetchCategoriesAsync() async -> [Category] {
        let request = NSFetchRequest<Category>(entityName: "Category")
        do {
            let results = try context.fetch(request)
            return results
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    // MARK: Local fetch
    private func fetchLocalNote(with id: UUID) -> Note? {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching local note by ID: \(error)")
            return nil
        }
    }
    
    /// Example function for fetching categories
    private func fetchCategories() -> [Category] {
        let request = NSFetchRequest<Category>(entityName: "Category")
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
}


// MARK: - Private Helpers
extension ProfileView {
    private func saveProfileEdits() async {
        guard !editedProfile.id.isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            // 1) If using Supabase Storage for the new photo, upload and get URL:
            if let data = selectedImageData {
                isUploading = true
                do {
                    // Use StorageManager to upload the image
                    if let image = UIImage(data: data) {
                        let imagePath = try await StorageManager.shared.uploadProfileImage(image)
                        
                        // Get a public URL for the image
                        let imageUrl = try StorageManager.shared.getPublicURL(for: imagePath)
                        
                        // Update the profile with the new URL
                        editedProfile.profile_photo_url = imageUrl.absoluteString
                    } else {
                        throw StorageManager.StorageError.imageConversionFailed
                    }
                    
                    isUploading = false
                } catch {
                    isUploading = false
                    errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
                    return
                }
            }
            
            // 2) Prepare payload for updating in DB
            let updatePayload = ProfileUpdateRequest(
                username: editedProfile.username,
                display_name: editedProfile.display_name,
                profile_photo_url: editedProfile.profile_photo_url
            )
            
            // 3) Send update to "profiles" table
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(updatePayload)
                .eq("id", value: editedProfile.id)
                .single()
                .execute()
            
            // 4) If no error, exit edit mode & clear the temp image data
            isEditing = false
            selectedImageData = nil
            selectedImageItem = nil
        } catch {
            print("Caught error message in updating profile")
            errorMessage = "Error updating profile: \(error.localizedDescription)"
        }
    }
    
    private func cancelEditing() {
        // Discard unsaved changes
        isEditing = false
        errorMessage = nil
        selectedImageData = nil
        selectedImageItem = nil
    }
}

// MARK: - For the Update Payload
struct ProfileUpdateRequest: Encodable {
    let username: String?
    let display_name: String?
    let profile_photo_url: String?
}

// MARK: - Optional String Binding Helper
extension Binding where Value == String? {
    /// Maps an optional string to a non-optional one, substituting "" when `nil`.
    var orEmpty: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
