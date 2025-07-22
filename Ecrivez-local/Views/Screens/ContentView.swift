import SwiftUI
import CoreData
import RichTextKit
import PhotosUI
import CoreLocation
import MapKit
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }
    
    // MARK: - Core Data & Environment
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var premiumManager = PremiumManager.shared

    // MARK: - FetchRequests
    @FetchRequest(
        entity: Note.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.index, ascending: true)]
    ) var notes: FetchedResults<Note>

    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
    ) var categories: FetchedResults<Category>

    // MARK: - Local State
    @State private var selectedNote: Note?
    @State private var showingAddNoteView = false
    @State private var showingAuthView = false
    @State private var showBubbles = false
    @State private var selectedCategory: Category?
    
    @State private var noteToDelete: Note?
    @State private var showDeleteConfirmation = false
    @State private var indexSetToDelete: IndexSet?
    
    // Premium limiting states
    @State private var showLimitAlert = false
    @State private var showPaywall = false

    // Grid layout for iPad
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // For "Fold All"
    @State private var foldAll = false

    // For "Sort by Date" toggle
    @State private var sortByDateDesc = false

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Filtered + Sorted Notes
    var filteredNotes: [Note] {
        if let category = selectedCategory {
            // Filter by category
            return notes.filter { $0.category == category }
        } else {
            // No filter => show all
            return Array(notes)
        }
    }

    var displayedNotes: [Note] {
        // If user toggles date sort, use note.date
        // Otherwise, use note.index as the manual reorder
        if sortByDateDesc {
            // sort descending by date
            return filteredNotes.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        } else {
            // default to the "index" property for manual ordering
            return filteredNotes.sorted { $0.index < $1.index }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if isIPad {
                    // iPad two-column grid layout
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            // Top Bar
                            HStack {
                                Text("Ideas")
                                    .italic()
                                    .font(.title)
                                    .fontWeight(.medium)
                                Spacer()
                                
                                // Sync Status Indicator
                                if authVM.isAuthenticated && SyncManager.shared.syncEnabled {
                                    SyncStatusView()
                                }
                                
                                Button(action: {
                                    showingAuthView = true
                                }) {
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 24))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 15)
                            
                            // Category filter
                            CategoryFilterView(
                                selectedCategory: $selectedCategory,
                                categories: Array(categories),
                                foldAll: $foldAll,
                                sortByDateDesc: $sortByDateDesc
                            )
                            .font(.subheadline)
                            .padding(.bottom, 5)
                            
                            // Two-column grid of notes
                            ScrollView {
                                LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(displayedNotes) { note in
                                    NoteGridCell(
                                        note: note,
                                        foldAll: foldAll,
                                        onTap: { selectedNote = note },
                                        onDelete: {
                                            if let idx = displayedNotes.firstIndex(of: note) {
                                                indexSetToDelete = IndexSet(integer: idx)
                                                showDeleteConfirmation = true
                                            }
                                        },
                                        onMove: { fromID, toID in
                                            if let fromIdx = notes.firstIndex(where: { $0.id?.uuidString == fromID }),
                                               let toIdx = notes.firstIndex(where: { $0.id?.uuidString == toID }) {
                                                moveNote(from: IndexSet(integer: fromIdx), to: toIdx > fromIdx ? toIdx + 1 : toIdx)
                                            }
                                        }
                                    )
                                    }
                            }
                                .padding()
                                .frame(maxHeight: .infinity)
                        }
                            .background(Color(.systemGroupedBackground))
                            // Combined bubble menu and control buttons overlay for iPad
                            HStack(alignment: .bottom, spacing: 16) {
                                if showBubbles {
                                    BubbleMenuView(
                                        showBubbles: $showBubbles,
                                        selectedCategory: $selectedCategory,
                                        categories: Array(categories),
                                        onCategorySelected: {
                                            if premiumManager.canCreateMoreNotes(currentCount: notes.count) {
                                                showingAddNoteView = true
                                            } else {
                                                showLimitAlert = true
                                            }
                                        }
                                    )
                                }
                            iPadControlButtons
                            }
                            .padding(.top, 10)
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    // Original iPhone layout
                    ZStack {
                        Color(.systemBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                        // Top Bar
                        HStack {
                            Text("Ideas")
                                .italic()
                                .font(.title)
                                .fontWeight(.medium)
                            Spacer()
                            
                            // Sync Status Indicator
                            if authVM.isAuthenticated && SyncManager.shared.syncEnabled {
                                SyncStatusView()
                            }
                            
                            Button(action: {
                                showingAuthView = true
                            }) {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 24))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 15)
                        
                        // Category Filter + Fold/Sort Toggles
                        CategoryFilterView(
                            selectedCategory: $selectedCategory,
                            categories: Array(categories),
                            foldAll: $foldAll,
                            sortByDateDesc: $sortByDateDesc
                        )
                        .font(.subheadline)
                        .padding(.bottom, 5)
                        
                        // NOTES LIST
                        List {
                            ForEach(displayedNotes) { note in
                                NoteView(
                                    note: note,
                                    foldAll: foldAll,
                                    buttonTapped: {
                                        selectedNote = note
                                    }
                                )
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indexSet in
                                indexSetToDelete = indexSet
                                if let index = indexSet.first {
                                    noteToDelete = displayedNotes[index]
                                    showDeleteConfirmation = true
                                }
                            }
                            .onMove(perform: moveNote)
                            .moveDisabled(selectedCategory != nil || sortByDateDesc)
                        }
                        .listStyle(PlainListStyle())
                        .safeAreaInset(edge: .bottom) {
                            BubbleMenuView(
                                showBubbles: $showBubbles,
                                selectedCategory: $selectedCategory,
                                categories: Array(categories),
                                onCategorySelected: {
                                    if premiumManager.canCreateMoreNotes(currentCount: notes.count) {
                                        showingAddNoteView = true
                                    } else {
                                        showLimitAlert = true
                                    }
                                }
                            )
                        }
                        
                        // PLUS Button & Nav Buttons
                        ZStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        showBubbles.toggle()
                                    }
                                }) {
                                    Image(systemName: showBubbles ? "minus.circle.fill" : "plus.circle.fill")
                                        .font(.system(size: 52))
                                        .foregroundColor(.red)
                                }
                                Spacer()
                            }
                            .padding()
                            
                            HStack {
                                NavigationLink(destination: FeedView(isAuthenticated: authVM.isAuthenticated)) {
                                    Image(systemName: "text.bubble")
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)
                                        .padding(5)
                                        .clipShape(Circle())
                                }
                                .padding(.leading, 50)
                                
                                Spacer()
                                
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 50)
                            }
                        }
                    }
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        
        .confirmationDialog(
            "Are you sure you want to delete this note?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if let indexSet = indexSetToDelete {
                        await deleteNote(at: indexSet)
                        indexSetToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                noteToDelete = nil
                indexSetToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }

        // Save context on background
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                saveContext()
            }
        }
        
        // Present Note Editor when a note is selected (for both iPhone and iPad)
        .sheet(item: $selectedNote, onDismiss: {
            selectedNote = nil
        }) { note in
                NoteEditorView(
                    mode: .edit(note),
                    categories: Array(categories), context: context,
                    isAuthenticated: authVM.isAuthenticated,
                    onSave: { saveContext() }
                )
                .environmentObject(premiumManager)
        }
        
        // Present "Add Note" after picking category bubble
        .sheet(isPresented: $showingAddNoteView, onDismiss: {
            selectedCategory = nil
        }) {
            NoteEditorView(
                mode: .create(selectedCategory!),
                categories: Array(categories), context: context,
                isAuthenticated: authVM.isAuthenticated,
                onSave: { saveContext() }
            )
            .environmentObject(premiumManager)
        }
        // Auth / Profile sheet
        .sheet(isPresented: $showingAuthView) {
            if authVM.isAuthenticated {
                UserView(authVM: authVM)
            } else {
                AuthenticationView(authVM: authVM)
            }
        }
        // Note limit alert
        .alert("Note Limit Reached", isPresented: $showLimitAlert) {
            Button("Upgrade") {
                showPaywall = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You've reached the free tier limit of \(premiumManager.freeNoteLimit) notes. Upgrade to Premium for unlimited notes!")
        }
        // Paywall sheet
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // Floating control buttons with transparent background
    private var iPadControlButtons: some View {
        HStack {
            Spacer()
            
            // Create new note button
            Button(action: {
                // Show category selection
                withAnimation {
                    showBubbles.toggle()
                }
            }) {
                Image(systemName: showBubbles ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.red)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            
            // Feed button
            NavigationLink(destination: FeedView(isAuthenticated: authVM.isAuthenticated)) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    
                    Image(systemName: "text.bubble")
                        .font(.system(size: 20))
                    .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 10)
            
            // Settings button
            NavigationLink(destination: SettingsView()) {
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                    .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: - Deletions & Reordering

    private func deleteNote(at offsets: IndexSet) async {
        for index in offsets {
            let noteToDelete = displayedNotes[index]
            if let noteID = noteToDelete.id {
                do {
                    let exists = await NoteRepository.shared.noteExistsInSupabase(noteID: noteID)
                    if exists {
                        try await NoteRepository.shared.deletePublicNote(noteID)
                    }
                } catch {
                    print("Error deleting note from Supabase: \(error)")
                }
            }
            context.delete(noteToDelete)
        }
        saveContext()
    }

    private func moveNote(from source: IndexSet, to destination: Int) {
        // Because we store user-defined ordering in note.index,
        // we re-map notes, reorder them, then update each note.index
        var reorderedNotes = Array(notes)  // the entire fetch, unsorted
        reorderedNotes.move(fromOffsets: source, toOffset: destination)

        // Set new indexes
        for (newIndex, note) in reorderedNotes.enumerated() {
            note.index = Int16(newIndex)
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - CategoryFilterView
struct CategoryFilterView: View {
    @Binding var selectedCategory: Category?
    var categories: [Category]

    // For "Fold All" & "Sort by Date"
    @Binding var foldAll: Bool
    @Binding var sortByDateDesc: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            // Title row
            HStack {
                Text("Categories")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()

                HStack(spacing: 16) {
                    // Expand/collapse categories
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }

                    // Fold All
                    Button(action: {
                        withAnimation {
                            foldAll.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(foldAll ? .red : ((colorScheme == .dark) ? .white : .orange))
                    }

                    // Sort by Date
                    Button(action: {
                        withAnimation {
                            sortByDateDesc.toggle()
                        }
                    }) {
                        Image(systemName: "calendar")
                            .foregroundColor(sortByDateDesc ? .red : ((colorScheme == .dark) ? .white : .orange))
                    }
                }
            }
            .padding(.horizontal)
            

            // Bubbles, if expanded
            if isExpanded {
                VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // "All" button
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            Text("All")
                                .padding(8)
                                .background(selectedCategory == nil ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }

                        // Each category bubble
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedCategory == category ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                }
                .transition(.opacity)
                .padding(.bottom, 5)
            }
        }
    }
}

struct NoteGridCell: View {
    let note: Note
    let foldAll: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMove: (String, String) -> Void // (fromID, toID)

    var body: some View {
        NoteView(
            note: note,
            foldAll: foldAll,
            buttonTapped: onTap
        )
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onDrag {
            NSItemProvider(object: NSString(string: note.id?.uuidString ?? ""))
        }
        .onDrop(of: [.plainText], isTargeted: nil) { providers in
            if let provider = providers.first {
                let toID = note.id?.uuidString // capture before closure
                _ = provider.loadObject(ofClass: NSString.self) { (item, error) in
                    if let fromID = item as? String, let toID = toID {
                        DispatchQueue.main.async {
                            onMove(fromID, toID)
                        }
                    }
                }
                return true
            }
            return false
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Sync Status View
struct SyncStatusView: View {
    @ObservedObject private var syncManager = SyncManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            switch syncManager.syncStatus {
            case .idle:
                Image(systemName: "checkmark.icloud.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
            case .syncing:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
                
            case .success:
                Image(systemName: "checkmark.icloud.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
                
            case .error(_):
                Image(systemName: "exclamationmark.icloud.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: syncManager.syncStatus)
    }
}

