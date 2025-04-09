import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context

    // Store user preferences in UserDefaults
//    @AppStorage("defaultFontSize") private var defaultFontSize = 18
//    @AppStorage("defaultFontName") private var defaultFontName = "Helvetica"
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // A small list of fonts for demonstration
    private let availableFonts = [
        "Helvetica",
        "Courier",
        "Times New Roman",
        "AvenirNext-Regular",
        "Georgia"
    ]
    
    var body: some View {
        List {
            // Existing links
            NavigationLink(destination: CategoryEditorListView()) {
                Text("Edit Categories")
            }
            
//            NavigationLink(destination: CategoryEditorListView()) {
//                Text("Account Settings")
//            }

            NavigationLink(destination: SuggestFeatureView()) {
                Text("Suggest a Feature / Update")
            }
            
            NavigationLink(destination: DonationView()) {
                HStack {
                    Text("Support the developer ")
                    Image(systemName: "dollarsign.arrow.circlepath")
                        .font(.system(size: 24))
                }
                .foregroundColor(.yellow)
            }
            
            // MARK: - New Section for font & color mode
            Section(header: Text("Default Editor Settings")) {
                
//                // Font name picker
//                Picker("Font Family", selection: $defaultFontName) {
//                    ForEach(availableFonts, id: \.self) { font in
//                        Text(font).tag(font)
//                    }
//                }
//                
//                // Font size stepper
//                Stepper("Font Size: \(defaultFontSize)", value: $defaultFontSize, in: 8...48)
                
                // Toggle for Dark/Light mode
                Toggle("Dark Mode", isOn: $isDarkMode)
            }
        }
        .navigationTitle("Settings")
    }
}
