////
////  EnterUsernameView.swift
////  Ecrivez-local
////
////  Created by Tobias Fu on 12/23/24.
////
//
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
    // For picking a new profile photo
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    // For camera/photo library selection
    @State private var isShowingImagePicker = false
    @State private var isConfirmationDialogPresented = false
    @State private var imageSourceType: ImageSourceType = .photoLibrary
    
    enum ImageSourceType {
        case camera
        case photoLibrary
    }
    
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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: - Profile Photo
                profilePhotoSection
                
                // MARK: - Username & Display Name
                if isEditing {
                    editingFields
                } else {
                    staticProfileFields
                }
                
                Button ("Log out") {
                    authVM.signOut()
                }
                .buttonStyle(.borderedProminent)
                
                // Show any error messages
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                Divider()
                
                // MARK: - My Public Notes Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("My Public Notes")
                        .font(.headline)
                    
                    if isLoadingMyNotes {
                        ProgressView("Loading your notes...")
                    } else if let errorMessage {
                        Text("Error loading notes: \(errorMessage)")
                            .foregroundColor(.red)
                    } else if myNotes.isEmpty {
                        Text("No public notes found.")
                            .foregroundColor(.gray)
                    } else {
                        // Show each note in a vertical list
                        ForEach(myNotes) { supaNote in
                            buildRow(for: supaNote)
                            Divider()
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Your Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { try await loadMyPublicNotes() }
        }
        // Optional sheet for local note editing
        .sheet(isPresented: $showingNoteEditor) {
            if let note = selectedLocalNote {
                NoteEditorView(
                    mode: .edit(note),
                    categories: fetchCategories(), context: context,
                    isAuthenticated: authVM.isAuthenticated,
                    onSave: {
                        // Possibly re-fetch from supabase if needed
                    }
                )
            }
        }
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
    
    // MARK: Profile Photo
    @ViewBuilder
    var profilePhotoSection: some View {
        ZStack {
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                // Show the newly picked image (if in edit mode)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            }
            else if let profilePhotoUrl = editedProfile.profile_photo_url,
                    let url = URL(string: profilePhotoUrl) {
                // Show the existing photo from URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 120, height: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            else {
                // No image set, fallback to user icon
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
            
            // Show uploading indicator if applicable
            if isUploading {
                ProgressView()
                    .frame(width: 120, height: 120)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: Editing Fields
    @ViewBuilder
    var editingFields: some View {
        TextField("Username", text: $editedProfile.username.orEmpty)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
        
        TextField("Display Name", text: $editedProfile.display_name.orEmpty)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
        
        // Button to show image source options
        Button("Change Profile Photo") {
            isConfirmationDialogPresented = true
        }
        .confirmationDialog(
            "Select Image Source",
            isPresented: $isConfirmationDialogPresented,
            actions: {
                // If you want camera:
                Button("Camera") {
                    imageSourceType = .camera
                    isShowingImagePicker = true
                }
                // Or library:
                Button("Photo Library") {
                    imageSourceType = .photoLibrary
                    isShowingImagePicker = true
                }
            },
            message: {
                Text("Where do you want to pick an image from?")
            }
        )
        .sheet(isPresented: $isShowingImagePicker, onDismiss: {
            // Handle after picker is dismissed if needed
        }) {
            switch imageSourceType {
            case .camera:
                CameraImagePicker(imageData: $selectedImageData, sourceType: .camera)
            case .photoLibrary:
                PhotoLibraryPicker(selectedImage: $selectedImageData)
            }
        }
        
        // Still keep PhotosPicker as an alternate option if preferred
        PhotosPicker("Or Select from Photos App", selection: $selectedImageItem, matching: .images)
            .onChange(of: selectedImageItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        
        // Save/Cancel buttons
        HStack(spacing: 20) {
            Button("Save") {
                Task { await saveProfileEdits() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving || isUploading)
            
            Button("Cancel") {
                cancelEditing()
            }
            .buttonStyle(.bordered)
            .disabled(isSaving || isUploading)
        }
    }
    
    // MARK: Static Fields
    @ViewBuilder
    var staticProfileFields: some View {
        VStack(spacing: 5) {
            // Optional styling
            Text(editedProfile.username ?? "Username")
                .font(.headline)
            
            Text(editedProfile.display_name ?? "Display Name")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        
        // Edit Profile button
        Button("Edit Profile") {
            isEditing = true
        }
        .padding(.top, 10)
    }
    
    // MARK: Building the MyPublicNotes row
    @ViewBuilder
    func buildRow(for supaNote: SupabaseNote) -> some View {
        // Attempt to find a matching local note
        if let localNote = fetchLocalNote(with: supaNote.id) {
            // If local note exists, let user edit it
            HStack {
                Text(supaNote.content.prefix(40)) // or a custom UI
                Spacer()
                Button("Edit Note") {
                    selectedLocalNote = localNote
                    showingNoteEditor = true
                }
            }
        } else {
            // If note not found locally, only show a "Delete" button
            HStack {
                Text(supaNote.content.prefix(40))
                Spacer()
                Button(role: .destructive) {
                    Task { try await NoteRepository.shared.deletePublicNote(supaNote.id) }
                } label: {
                    Image(systemName: "trash")
                }
            }
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
                    let imagePath = try await StorageManager.shared.uploadProfileImage(UIImage(data: data)!)
                    
                    // Get a public URL for the image
                    let imageUrl = try StorageManager.shared.getPublicURL(for: imagePath)
                    
                    // Update the profile with the new URL
                    editedProfile.profile_photo_url = imageUrl.absoluteString
                    
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
