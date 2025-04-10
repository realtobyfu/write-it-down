//
//  NoteEditorViewModel.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 3/23/25.
//
import SwiftUI
import CoreLocation
import CoreData

@MainActor
class NoteEditorViewModel: ObservableObject {
    
    // MARK: - Published properties
    @Published var attributedText: NSAttributedString = .init(string: "")
    @Published var selectedDate: Date?
    @Published var location: CLLocationCoordinate2D?
    @Published var weather: String = ""
    @Published var category: Category
    @Published var isPublic: Bool = false
    @Published var isAnonymous: Bool = false
    @Published var locationName: String?
    @Published var locationLocality: String?
    @Published var showDeleteConfirmation = false

    // MARK: - Private properties
    private let context: NSManagedObjectContext
    private(set) var existingNote: Note?

    // MARK: - Initializer
    init(mode: NoteEditorView.Mode, context: NSManagedObjectContext) {
        self.context = context

        // Decide initial property values
        switch mode {
        case .edit(let note):
            self.existingNote = note
            self.attributedText = note.attributedText
            self.selectedDate   = note.date
            self.isPublic       = note.isPublic
            self.isAnonymous    = note.isAnnonymous
            self.location       = note.location?.coordinate
            self.locationName   = note.locationName
            self.locationLocality = note.locationLocality // Initialize locality from note
            self.category       = note.category!   // Force unwrap or handle fallback
            self.weather        = "" // or note.weather if you store it in Core Data
        case .create(let cat):
            // New note scenario
            self.existingNote = nil
            self.category = cat
            // The rest remain at default/empty
        }
    }

    // MARK: - Save note logic
    func saveNote(isAuthenticated: Bool) async {
        
        print("Attributed Text to be saved \(attributedText)")
        
        let noteToSave = existingNote ?? Note(context: context)
        noteToSave.id = noteToSave.id ?? UUID()
        noteToSave.attributedText = attributedText
        noteToSave.category = category
        noteToSave.date = selectedDate
        noteToSave.isPublic = isPublic
        noteToSave.isAnnonymous = isAnonymous
        noteToSave.locationName = locationName
        noteToSave.locationLocality = locationLocality // Save locality field
        noteToSave.location = location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }

        do {
            try context.save()

            context.refresh(noteToSave, mergeChanges: true)
            print("Fetched back from context: \(noteToSave.attributedText)")

            if isAuthenticated {
                if isPublic {
                    // Insert or update in Supabase
                    let user = try await SupabaseManager.shared.client.auth.user()
                    try await NoteRepository.shared.upsertPublicNote(noteToSave, ownerID: user.id)
                } else {
                    // If user made it private, remove from Supabase if it existed
                    if let noteID = noteToSave.id {
                        let exists = await NoteRepository.shared.noteExistsInSupabase(noteID: noteID)
                        if exists {
                            try await NoteRepository.shared.deletePublicNote(noteID)
                        }
                    }
                }
            }
        } catch {
            print("Failed to save note:", error)
        }
    }
}
