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
            self.locationName   = note.placeName
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
        noteToSave.placeName = locationName ?? ""
        noteToSave.location = location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }

        do {
            try context.save()

            context.refresh(noteToSave, mergeChanges: true)
            print("Fetched back from context: \(noteToSave.attributedText)")

            if isAuthenticated {
                await updateSupabase(note: noteToSave)
            }
        } catch {
            print("Failed to save note:", error)
        }
    }

    // MARK: - Supabase Integration
    private func updateSupabase(note: Note) async {
        do {
            let user = try await SupabaseManager.shared.client.auth.user()
            let rtfData = try note.attributedText.data(
                from: NSRange(location: 0, length: note.attributedText.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            let base64RTF = rtfData.base64EncodedString()

            let supaNote = SupabaseNote(
                id: note.id!,
                owner_id: user.id,
                category_id: note.category?.id,
                content: note.attributedText.string,
                rtf_content: base64RTF,
                date: note.date,
                locationName: note.placeName,
                locationLatitude: note.locationLatitude?.stringValue,
                locationLongitude: note.locationLongitude?.stringValue,
                colorString: note.category?.colorString ?? "",
                symbol: note.category?.symbol ?? "",
                isAnnonymous: note.isAnnonymous
            )

            if note.isPublic {
                if await checkExistInDB(note: note) {
                    try await SupabaseManager.shared.client
                        .from("public_notes")
                        .update(supaNote)
                        .eq("id", value: note.id!)
                        .execute()
                } else {
                    try await SupabaseManager.shared.client
                        .from("public_notes")
                        .insert(supaNote)
                        .execute()
                }
            } else {
                if await checkExistInDB(note: note) {
                    try await SupabaseManager.shared.client
                        .from("public_notes")
                        .delete()
                        .eq("id", value: note.id!)
                        .execute()
                }
            }
        } catch {
            print("Supabase error:", error)
        }
    }

    private func checkExistInDB(note: Note) async -> Bool {
        guard let id = note.id else { return false }
        do {
            let response: [SupabaseNote] = try await SupabaseManager.shared.client
                .from("public_notes")
                .select()
                .eq("id", value: id)
                .execute()
                .value
            return !response.isEmpty
        } catch {
            print("Check existence error:", error)
            return false
        }
    }
}
