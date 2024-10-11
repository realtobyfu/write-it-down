import SwiftUI

struct SettingsView: View {
    @Binding var categories: [Category]

    var body: some View {
        List {
            NavigationLink(destination: CategoryEditorListView(categories: $categories)) {
                HStack {
                    Image(systemName: "paintpalette")
                    Text("Edit Categories")
                }
            }

            // Add more settings here as needed
            // For example:
            // NavigationLink(destination: NotificationSettingsView()) {
            //     HStack {
            //         Image(systemName: "bell")
            //         Text("Notifications")
            //     }
            // }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    @State static var categories: [Category] = [
        Category(symbol: "book", colorName: "green", name: "Book"),
        Category(symbol: "fork.knife", colorName: "blue", name: "Cooking"),
        Category(symbol: "sun.min", colorName: "yellow", name: "Day"),
        Category(symbol: "movieclapper", colorName: "pink", name: "Movie"),
        Category(symbol: "message.badge.filled.fill", colorName: "brown", name: "Message"),
        Category(symbol: "list.bullet", colorName: "gray", name: "List")
    ]

    static var previews: some View {
        SettingsView(categories: $categories)
    }
}
