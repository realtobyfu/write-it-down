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

struct ProfileView: View {
    
    @ObservedObject var authVM: AuthViewModel
    
    @State private var isEditing = false
    
    // The user’s profile that we’re displaying or editing
    @State var editedProfile: Profile
    
    // For picking a new profile photo
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    // For error / saving state
    @State private var errorMessage: String?
    @State private var isSaving = false

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
            Task { await loadMyPublicNotes() }
        }
        // Optional sheet for local note editing
        .sheet(isPresented: $showingNoteEditor) {
            if let note = selectedLocalNote {
                NoteEditorView(
                    mode: .edit(note),
                    categories: fetchCategories(),
                    isAuthenticated: authVM.isAuthenticated,
                    onSave: {
                        // Possibly re-fetch from supabase if needed
                    }
                )
            }
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
        
        // Photo picker for changing the profile pic
        PhotosPicker("Select Photo", selection: $selectedImageItem, matching: .images)
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
            .disabled(isSaving)
            
            Button("Cancel") {
                cancelEditing()
            }
            .buttonStyle(.bordered)
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
                    Task { await deleteFromSupabase(supaNote.id) }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
    
    // MARK: Loading the User's Public Notes
    private func loadMyPublicNotes() async {
        guard let userID = try? await SupabaseManager.shared.client.auth.user().id else {
            errorMessage = "No user session found."
            return
        }
        
        isLoadingMyNotes = true
        errorMessage = nil
        defer { isLoadingMyNotes = false }
        
        do {
            let notes: [SupabaseNote] = try await SupabaseManager.shared.client
                .from("public_notes")
                .select()
                .eq("owner_id", value: userID)
                .order("date", ascending: false)
                .execute()
                .value
            
            myNotes = notes
        } catch {
            errorMessage = "Failed to load your public notes: \(error)"
        }
    }
    
    // MARK: Deleting a note from Supabase
    private func deleteFromSupabase(_ noteID: UUID) async {
        do {
            try await SupabaseManager.shared.client
                .from("public_notes")
                .delete()
                .eq("id", value: noteID)
                .execute()
            
            // Remove from myNotes
            if let idx = myNotes.firstIndex(where: { $0.id == noteID }) {
                myNotes.remove(at: idx)
            }
        } catch {
            errorMessage = "Error deleting note from Supabase: \(error)"
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
//            // 1) If using Supabase Storage for the new photo, upload and get URL:
//            if let data = selectedImageData {
//                let newImageURL = try await uploadToSupabaseStorage(data)
//                editedProfile.profile_photo_url = newImageURL
//            }
            
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
//    
//    /// Example function for uploading the raw image data to Supabase storage
//    /// and returning a URL string. You'll need to adapt this to your project.
//    private func uploadToSupabaseStorage(_ data: Data) async throws -> String {
//        // Generate a unique filename
//        let fileName = "\(editedProfile.id)_\(UUID().uuidString).jpg"
//        
//        // 1) Upload to your "avatars" (example) bucket
//        let response = try await SupabaseManager.shared.client
//            .storage
//            .from("avatars") // your bucket name
//            .upload(
//                fileName,
//                data: data
//            )
//        
//        // 2) If your bucket is public, build a public URL
//        // Replace {SUPABASE_URL} with your actual project ref
//        let url = "https://YOUR-PROJECT-REF.supabase.co/storage/v1/object/public/avatars/\(fileName)"
//        return url
//    }
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
