//
//  Write_It_Down_localTests.swift
//  Write-It-Down-localTests
//
//  Created by Tobias Fu on 3/11/25.
//

import Testing
import CoreData
import Foundation
@testable import Ecrivez_local
import UIKit



@Suite("Main tests")
@MainActor
struct Write_It_Down_localTests {
    @Test
    func testCreateMode() async throws {
        // 1) Set up an in-memory container
        let container = NSPersistentContainer(name: "Model")
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.url = URL(fileURLWithPath: "dev/null")
        container.loadPersistentStores { desc, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        let context = container.viewContext
        
        // 2) Create a sample category
        let sampleCategory = Category(context: context)
        sampleCategory.id = UUID()
        sampleCategory.name = "Test Category"
        sampleCategory.colorString = "blue"
        sampleCategory.symbol = "book"
        
        // 3) Initialize ViewModel in Create Mode
        let mode: NoteEditorView.Mode = .create(sampleCategory)
        let viewModel = NoteEditorViewModel(mode: mode, context: context)
        
        // 4) Simulate user input in the ViewModel
        viewModel.attributedText = NSAttributedString(string: "Hello from create mode!")
        viewModel.isPublic = false
        viewModel.isAnonymous = false
        viewModel.category = sampleCategory
        viewModel.selectedDate = Date()
        
        // 5) Call save
        await viewModel.saveNote(isAuthenticated: true)

        // 6) Fetch all notes and check
        let request = NSFetchRequest<Note>(entityName: "Note")
        let results = try context.fetch(request)

        #expect(results.count == 1)
        let note = results.first!
        #expect(note.attributedText.string == "Hello from create mode!")
        #expect(!note.isPublic)
        #expect(!note.isAnnonymous)
        #expect(note.date != nil)
        #expect(note.category != nil)
        
    }
}




@Suite("Standalone Tests")
struct standalone_tests {
    @Test
    func testFontDecoding() throws {
        
        let originalFont = UIFont(name: "Courier-Bold", size: 14)!
        let originalString = NSAttributedString(string: "Testing font", attributes: [
            .font: originalFont
        ])
        
        print("Local Test - Original String:", originalString)
        
        let rtfData = try originalString.data(
            from: NSRange(location: 0, length: originalString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        
        let decoded = try NSAttributedString(
            data: rtfData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )

        print("Local Test, Decoded:", decoded)
        
        #expect(originalString == decoded)
    }
}
