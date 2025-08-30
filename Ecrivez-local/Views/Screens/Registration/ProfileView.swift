import SwiftUI
import Storage
import CoreData
import UIKit

struct ProfileView: View {
    
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var premiumManager = PremiumManager.shared
    
    @State private var isEditing = false
    
    // The user's profile that we're displaying or editing
    @State var editedProfile: Profile
    
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
    
    // Add a loading state
    @State private var isLoadingEditor = false

    // Pre-fetch categories in onAppear rather than during sheet presentation
    @State private var cachedCategories: [Category] = []

    // Add state for showing authentication view
    @State private var showingAuthView = false
    @State private var showingPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with profile photo and name
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 200)
                    
                    VStack(spacing: 16) {
                        profilePhotoSection
                            .shadow(radius: 4)
                        
                        if !isEditing {
                            VStack(spacing: 8) {
                                Text(editedProfile.display_name ?? "Display Name")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Text("@\(editedProfile.username ?? "username")")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(.vertical, 24)
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
                        .padding(.top, 8)
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
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cloud Sync")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if !authVM.isAuthenticated {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("Sign in to enable syncing across devices")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                
                                Button(action: {
                                    showingAuthView = true
                                }) {
                                    Label("Sign In", systemImage: "person.fill.badge.plus")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                        } else if premiumManager.hasAccess(to: .cloudSync) {
                            SyncControlView()
                                .padding(.vertical, 8)
                        } else {
                            // Premium upgrade section for sync
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Cloud Sync")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("Sync your notes across all devices")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Automatic backup to cloud")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Access notes on all devices")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Never lose your notes")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                }
                                
                                Button(action: {
                                    showingPaywall = true
                                }) {
                                    Text("Upgrade to Premium")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
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
                .environmentObject(premiumManager)
            }
        }
        // Present authentication sheet when showingAuthView is true
        .sheet(isPresented: $showingAuthView) {
            AuthenticationView(authVM: authVM)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
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
                .disabled(isSaving)
                
                Button(action: { Task { await saveProfileEdits() } }) {
                    if isSaving {
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
                .disabled(isSaving)
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
            // Prepare payload for updating in DB
            let updatePayload = ProfileUpdateRequest(
                username: editedProfile.username,
                display_name: editedProfile.display_name,
                profile_photo_url: editedProfile.profile_photo_url
            )
            
            // Send update to "profiles" table
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(updatePayload)
                .eq("id", value: editedProfile.id)
                .single()
                .execute()
            
            // If no error, exit edit mode
            isEditing = false
        } catch {
            print("Caught error message in updating profile")
            errorMessage = "Error updating profile: \(error.localizedDescription)"
        }
    }
    
    private func cancelEditing() {
        // Discard unsaved changes
        isEditing = false
        errorMessage = nil
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
