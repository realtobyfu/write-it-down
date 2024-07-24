import SwiftUI

struct ContentView: View {
    @State private var notes: [String] = []
    @State private var newNote: String = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter new note", text: $newNote, onCommit: {
                    if !newNote.isEmpty {
                        notes.append(newNote)
                        newNote = ""
                    }
                })
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

                List {
                    ForEach(notes, id: \.self) { note in
                        Text(note)
                    }
                    .onDelete(perform: deleteNote)
                }
            }
            .navigationBarTitle("Notes")
            .navigationBarItems(trailing: EditButton())
        }
    }

    private func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

