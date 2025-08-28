import SwiftUI

struct MapPinCustomizationView: View {
    @StateObject private var settingsManager = UserSettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Live Preview Section
                    previewSection
                    
                    // Color Selection Section
                    colorSelectionSection
                    
                    // Icon Selection Section
                    iconSelectionSection
                    
                    // Reset Section
                    resetSection
                }
                .padding()
            }
            .navigationTitle("Map Pin Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 120)
                
                VStack(spacing: 8) {
                    // Preview Pin
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(radius: 4)
                        
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: settingsManager.settings.pinIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Your Custom Pin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var colorSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Pin Color")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: colorColumns, spacing: 12) {
                ForEach(UserSettings.availableColors, id: \.self) { colorName in
                    Button(action: {
                        settingsManager.settings.pinColor = colorName
                    }) {
                        ZStack {
                            Circle()
                                .fill(colorFromString(colorName))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: settingsManager.settings.pinColor == colorName ? 3 : 0)
                                )
                                .shadow(radius: 2)
                            
                            if settingsManager.settings.pinColor == colorName {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var iconSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Pin Icon")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: iconColumns, spacing: 12) {
                ForEach(UserSettings.availableIcons, id: \.self) { iconName in
                    Button(action: {
                        settingsManager.settings.pinIcon = iconName
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(settingsManager.settings.pinIcon == iconName ? selectedColor.opacity(0.2) : Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(settingsManager.settings.pinIcon == iconName ? selectedColor : Color.clear, lineWidth: 2)
                                )
                            
                            Image(systemName: iconName)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(settingsManager.settings.pinIcon == iconName ? selectedColor : .primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var resetSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                settingsManager.settings.pinColor = "blue"
                settingsManager.settings.pinIcon = "map.pin"
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Defaults")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Note: Category-specific pins will override these default settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
    
    private var selectedColor: Color {
        return colorFromString(settingsManager.settings.pinColor)
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

#Preview {
    MapPinCustomizationView()
}