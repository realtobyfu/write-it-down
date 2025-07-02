import SwiftUI

struct EditorPreferencesView: View {
    @StateObject private var settingsManager = UserSettingsManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var previewText = "The quick brown fox jumps over the lazy dog"
    
    var body: some View {
        Form {
            // Font Settings Section
            fontSection
            
            // Default Note Settings
            defaultsSection
            
            // Auto-save Settings
            autoSaveSection
            
            // Preview Section
            previewSection
        }
        .navigationTitle("Editor Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var fontSection: some View {
        Section(header: Text("Text Formatting")) {
            Picker("Font Family", selection: $settingsManager.settings.defaultFontName) {
                ForEach(UserSettings.availableFonts, id: \.self) { font in
                    Text(font)
                        .font(font == "System" ? .system(size: 16) : .custom(font, size: 16))
                        .tag(font)
                }
            }
            
            HStack {
                Text("Font Size")
                Spacer()
                Text("\(Int(settingsManager.settings.defaultFontSize))")
                    .foregroundColor(.secondary)
                Stepper("", value: $settingsManager.settings.defaultFontSize, in: 12...32, step: 1)
                    .labelsHidden()
            }
            
            Toggle("Show Rich Text Toolbar", isOn: $settingsManager.settings.showRichTextToolbar)
        }
    }
    
    private var defaultsSection: some View {
        Section(header: Text("Default Note Settings")) {
            Picker("Note Type", selection: $settingsManager.settings.defaultNoteType) {
                Label("Note", systemImage: "note.text").tag("note")
                Label("List", systemImage: "list.bullet").tag("list")
                Label("Task", systemImage: "checklist").tag("task")
            }
            
            HStack {
                Label("Default Color", systemImage: "paintpalette")
                Spacer()
                ForEach(UserSettings.availableColors, id: \.self) { color in
                    Circle()
                        .fill(Color(color))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: settingsManager.settings.defaultNoteColor == color ? 2 : 0)
                        )
                        .onTapGesture {
                            settingsManager.settings.defaultNoteColor = color
                        }
                }
            }
            
            Picker("Default Symbol", selection: $settingsManager.settings.defaultNoteSymbol) {
                ForEach(["note.text", "star", "heart", "flag", "bookmark", "tag"], id: \.self) { symbol in
                    Label(symbol, systemImage: symbol).tag(symbol)
                }
            }
        }
    }
    
    private var autoSaveSection: some View {
        Section(header: Text("Auto-Save"), footer: Text("Notes are automatically saved at the specified interval")) {
            Picker("Auto-Save Interval", selection: $settingsManager.settings.autoSaveInterval) {
                Text("15 seconds").tag(TimeInterval(15))
                Text("30 seconds").tag(TimeInterval(30))
                Text("1 minute").tag(TimeInterval(60))
                Text("2 minutes").tag(TimeInterval(120))
                Text("5 minutes").tag(TimeInterval(300))
            }
        }
    }
    
    private var previewSection: some View {
        Section(header: Text("Preview")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Font Preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(previewText)
                    .font(settingsManager.settings.defaultFontName == "System" ?
                          .system(size: settingsManager.settings.defaultFontSize) :
                            .custom(settingsManager.settings.defaultFontName, size: settingsManager.settings.defaultFontSize))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    NavigationView {
        EditorPreferencesView()
    }
}