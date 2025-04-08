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
                
                HStack {
                    // Edit Profile button
                    Button("Edit Profile") {
                        isEditing = true
                    }
                    .padding(.trailing, 10)

                    Button("Log out") {
                        authVM.signOut()
                    }
                    .buttonStyle(.borderedProminent)
                }
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
        .onAppear {
            // Ensure quick presentation with loading indicator
            isLoadingEditor = true
            
            // Load resources on a background thread
            Task {
                // Fetch the categories asynchronously
                cachedCategories = await fetchCategoriesAsync()
                
                // Signal that loading is complete
                isLoadingEditor = false
            }
        }

        // Camera picker sheet
        .sheet(isPresented: $isShowingCameraPicker, onDismiss: {
            if let imageData = selectedImageData {
                print("Camera picker dismissed with \(imageData.count) bytes of image data")
            } else {
                print("Camera picker dismissed without setting image data")
            }
        }) {
            CameraImagePicker(imageData: $selectedImageData, sourceType: .camera)
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

    // MARK: Profile Photo
    @ViewBuilder
    var profilePhotoSection: some View {
        ZStack {
//            if let selectedImageData,
//               let uiImage = UIImage(data: selectedImageData) {
//                // Show the newly picked image (if in edit mode)
//                Image(uiImage: uiImage)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 120, height: 120)
//                    .clipShape(Circle())
//                    .onAppear {
//                        print("Displaying newly selected image: \(selectedImageData.count) bytes")
//                    }
//            }
//            else if let profilePhotoUrl = editedProfile.profile_photo_url,
//                    let url = URL(string: profilePhotoUrl) {
//                // Show the existing photo from URL
//                AsyncImage(url: url) { phase in
//                    switch phase {
//                    case .empty:
//                        ProgressView()
//                            .frame(width: 80, height: 80)
//                    case .success(let image):
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 120, height: 120)
//                            .clipShape(Circle())
//                    case .failure(let error):
//                        Image(systemName: "person.crop.circle")
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 120, height: 120)
//                            .foregroundColor(.gray)
//                            .onAppear {
//                                print("Failed to load profile image URL: \(error)")
//                            }
//                    @unknown default:
//                        EmptyView()
//                    }
//                }
//            }
//            else {
                // No image set, fallback to user icon
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .foregroundColor(.blue)
//            }
            
            // Show uploading indicator if applicable
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
        
        // Use a combination of confirmation dialog for camera and PhotosPicker for library
//        VStack(spacing: 12) {
//            Button("Change Profile Photo") {
//                isConfirmationDialogPresented = true
//            }
//            .confirmationDialog(
//                "Select Image Source",
//                isPresented: $isConfirmationDialogPresented,
//                actions: {
//                    Button("Take Photo") {
//                        isShowingCameraPicker = true
//                    }
//
//                    // Instead of a button for photo library, we'll use the PhotosPicker below
//                    Button("Cancel", role: .cancel) { }
//                },
//                message: {
//                    Text("How would you like to add a photo?")
//                }
//            )
//
//            // Using the native PhotosPicker that is known to work
//            PhotosPicker("Select from Photos", selection: $selectedImageItem, matching: .images)
//                .onChange(of: selectedImageItem) { newItem in
//                    Task {
//                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
//                            selectedImageData = data
//                            print("PhotosPicker: Image data loaded successfully: \(data.count) bytes")
//                        }
//                    }
//                }
//        }
        
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
