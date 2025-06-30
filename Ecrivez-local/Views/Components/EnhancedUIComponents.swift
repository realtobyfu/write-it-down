import SwiftUI
import CoreLocation
import RichTextKit

// MARK: - Enhanced Metadata Section
struct NoteMetadataView: View {
    @Binding var selectedDate: Date?
    @Binding var location: CLLocationCoordinate2D?
    @Binding var locationName: String?
    @Binding var locationLocality: String?
    @Binding var weather: String
    @Binding var showingLocationPicker: Bool
    @Binding var showingWeatherPicker: Bool
    @Binding var showingImagePicker: Bool
    @Binding var imageSourceType: NoteEditorView.ImageSourceType
    
    @State private var showDatePicker = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon Toolbar
            HStack(spacing: 30) {
                // Date Icon
                Button(action: { showDatePicker = true }) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())

                // Location Icon
                Button(action: { showingLocationPicker = true }) {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                .buttonStyle(PlainButtonStyle())

                // Weather Icon
                Button(action: { showingWeatherPicker = true }) {
                    Image(systemName: weatherIcon)
                        .font(.title2)
                        .foregroundColor(weatherColor)
                }
                .buttonStyle(PlainButtonStyle())

                // Photo Icon (menu)
                Menu {
                    Button(action: {
                        imageSourceType = .camera
                        showingImagePicker = true
                    }) {
                        Label("Take Photo", systemImage: "camera")
                    }
                    Button(action: {
                        imageSourceType = .photoLibrary
                        showingImagePicker = true
                    }) {
                        Label("Choose Photo", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Selected Items Display
            if hasSelectedMetadata {
                VStack(alignment: .leading, spacing: 8) {
                    // Date Display
                    if let date = selectedDate {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(dateFormatter.string(from: date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: { selectedDate = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    
                    // Location Display
                    if location != nil {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text(locationDisplayText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Button(action: { 
                                location = nil
                                locationName = nil
                                locationLocality = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, hasSelectedMetadata ? 16 : 12)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6),
                            colorScheme == .dark ? Color(.systemGray5).opacity(0.5) : Color(.systemGray6).opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack(spacing: 16) {
                    DatePicker("", selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding(.horizontal)
                    .labelsHidden()
                    
                    if selectedDate != nil {
                        Button("Clear Date") {
                            selectedDate = nil
                            showDatePicker = false
                        }
                        .foregroundColor(.red)
                        .padding(.bottom)
                    }
                }
                // .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Weather icon and color
    private var weatherIcon: String {
        switch weather {
        case "Sunny": return "sun.max.fill"
        case "Cloudy": return "cloud.fill"
        case "Partly Cloudy": return "cloud.sun.fill"
        case "Rainy": return "cloud.rain.fill"
        case "Stormy": return "cloud.bolt.fill"
        case "Snowy": return "snow"
        default: return "cloud"
        }
    }

    private var weatherColor: Color {
        switch weather {
        case "Sunny": return .orange
        case "Cloudy": return .gray
        case "Partly Cloudy": return .blue
        case "Rainy": return .blue
        case "Stormy": return .purple
        case "Snowy": return .cyan
        default: return .gray
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    private var locationDisplayText: String {
        if let name = locationName, !name.isEmpty {
            return name
        } else if let locality = locationLocality, !locality.isEmpty {
            return locality
        }
        return "Selected Location"
    }

    private var hasSelectedMetadata: Bool {
        selectedDate != nil || location != nil
    }
}

// MARK: - Metadata Row Component
struct MetadataRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let showClearButton: Bool
    let onTap: () -> Void
    let onClear: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                // Title and Value
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                Spacer()
                
                // Clear button
                if showClearButton {
                    Button(action: {
                        onClear()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : .white)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Privacy Toggle
struct PrivacyToggleView: View {
    @Binding var isPublic: Bool
    @Binding var isAnonymous: Bool
    let isAuthenticated: Bool
    
    @State private var showPublicInfo = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if isAuthenticated {
            VStack(alignment: .leading, spacing: 16) {
                // Public Toggle with animation
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Publicly")
                                .font(.subheadline)
                            Text("Others can see and interact with this note")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: isPublic ? "globe" : "lock.fill")
                            .foregroundColor(isPublic ? .blue : .gray)
                            .animation(.spring(response: 0.3), value: isPublic)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPublic)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // Anonymous Toggle (only shown when public)
                if isPublic {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Post Anonymously")
                                    .font(.subheadline)
                                Text("Hide your username from others")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: isAnonymous ? "person.fill.questionmark" : "person.fill")
                                .foregroundColor(isAnonymous ? .purple : .gray)
                                .animation(.spring(response: 0.3), value: isAnonymous)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isAnonymous)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPublic)
        }
    }
}

// MARK: - Enhanced Category Selection
struct EnhancedCategorySelectionView: View {
    @Binding var selectedCategory: Category
    let categories: [Category]
    
    @State private var showAllCategories = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Selected Category Display
            HStack {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { 
                    withAnimation(.spring()) {
                        showAllCategories.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(selectedCategory.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: selectedCategory.symbol ?? "folder")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            )
                        
                        Text(selectedCategory.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Image(systemName: showAllCategories ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    )
                }
            }
            
            // Category Grid (when expanded)
            if showAllCategories {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                    ForEach(categories.sorted(by: { $0.index < $1.index }), id: \.self) { category in
                        CategoryGridItem(
                            category: category,
                            isSelected: category == selectedCategory,
                            onTap: {
                                withAnimation(.spring()) {
                                    selectedCategory = category
                                    showAllCategories = false
                                }
                            }
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
        )
    }
}

struct CategoryGridItem: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Circle()
                    .fill(category.color)
                    .frame(width: isSelected ? 50 : 44, height: isSelected ? 50 : 44)
                    .overlay(
                        Image(systemName: category.symbol ?? "folder")
                            .foregroundColor(.white)
                            .font(isSelected ? .title3 : .body)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: isSelected ? 3 : 0)
                    )
                
                if let name = category.name {
                    Text(name)
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
} 
