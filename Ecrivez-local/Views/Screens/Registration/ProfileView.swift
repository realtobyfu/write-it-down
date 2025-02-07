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

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Profile Photo
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
            
            // MARK: - Username & Display Name
            if isEditing {
                // TextFields for editing
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
            } else {
                // Static text display
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
            
            Button ("Log out") {
                authVM.signOut()
            }
            .buttonStyle(.borderedProminent)

            // Show any error messages
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Your Profile")
        .navigationBarTitleDisplayMode(.inline)
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
