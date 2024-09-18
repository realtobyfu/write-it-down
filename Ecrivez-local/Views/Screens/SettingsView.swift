import SwiftUI

struct SettingsView: View {
    @Binding var categories: [Category]

    var body: some View {
        NavigationView {
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
}

struct SettingsView_Previews: PreviewProvider {
    @State static var categories: [Category] = [
        Category(symbol: "book", colorName: "green"),
        Category(symbol: "fork.knife", colorName: "blue"),
        Category(symbol: "sun.min", colorName: "yellow"),
        Category(symbol: "movieclapper", colorName: "pink"),
        Category(symbol: "clapperboard", colorName: "brown"),
        Category(symbol: "paperplane", colorName: "gray")
    ]
    
    static var previews: some View {
        SettingsView(categories: $categories)
    }
}
