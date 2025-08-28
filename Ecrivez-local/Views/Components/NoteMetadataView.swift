import SwiftUI
import CoreLocation

struct NoteMetadataView: View {
    @Binding var selectedDate: Date?
    @Binding var location: CLLocationCoordinate2D?
    @Binding var locationName: String?
    @Binding var locationLocality: String?
    @Binding var weather: String
    @Binding var showingLocationPicker: Bool
    @Binding var showingWeatherPicker: Bool
    @Binding var showingImagePicker: Bool
    @Binding var imageSourceType: UIImagePickerController.SourceType
    let premiumManager: PremiumManager
    
    @State private var isDatePressed = false
    @State private var isLocationPressed = false
    @State private var isWeatherPressed = false
    @State private var isPhotoPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Main metadata icon bar
            HStack(spacing: 32) {
                // Date button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isDatePressed.toggle()
                    }
                    if selectedDate == nil {
                        selectedDate = Date()
                    } else {
                        selectedDate = nil
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isDatePressed = false
                    }
                }) {
                    Image(systemName: selectedDate != nil ? "calendar.badge.checkmark" : "calendar")
                        .font(.title2)
                        .foregroundColor(selectedDate != nil ? .blue : .gray)
                        .scaleEffect(isDatePressed ? 0.85 : 1.0)
                }
                
                // Location button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLocationPressed.toggle()
                    }
                    showingLocationPicker = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isLocationPressed = false
                    }
                }) {
                    Image(systemName: location != nil ? "location.fill" : "location")
                        .font(.title2)
                        .foregroundColor(location != nil ? Color(red: 1.0, green: 0.42, blue: 0.28) : .gray)
                        .scaleEffect(isLocationPressed ? 0.85 : 1.0)
                }
                
                // Weather button
                Button(action: {
                    if premiumManager.hasAccess(to: .weatherTagging) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isWeatherPressed.toggle()
                        }
                        showingWeatherPicker = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isWeatherPressed = false
                        }
                    }
                }) {
                    Image(systemName: getWeatherIcon())
                        .font(.title2)
                        .foregroundColor(getWeatherColor())
                        .scaleEffect(isWeatherPressed ? 0.85 : 1.0)
                }
                .disabled(!premiumManager.hasAccess(to: .weatherTagging))
                
                // Image button
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
                        .foregroundColor(showingImagePicker ? .purple : .gray)
                        .scaleEffect(isPhotoPressed ? 0.85 : 1.0)
                }
                .disabled(!premiumManager.hasAccess(to: .imageInsertion))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPhotoPressed.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPhotoPressed = false
                    }
                }
            }
            .padding(.horizontal)
            
            // Bottom info display
            if selectedDate != nil || location != nil {
                HStack(spacing: 12) {
                    // Date display
                    if let date = selectedDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.footnote)
                                .foregroundColor(.blue.opacity(0.8))
                            Text(date, style: .date)
                                .font(.footnote)
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6).opacity(0.8))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Location display
                    if let name = locationName {
                        Button(action: {
                            showingLocationPicker = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.footnote)
                                    .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.28).opacity(0.8))
                                Text(name)
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6).opacity(0.8))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func getWeatherIcon() -> String {
        if weather.isEmpty {
            return "cloud"
        }
        
        switch weather {
        case "Sunny":
            return "sun.max.fill"
        case "Partly Cloudy":
            return "cloud.sun.fill"
        case "Cloudy":
            return "cloud.fill"
        case "Rainy":
            return "cloud.rain.fill"
        case "Stormy":
            return "cloud.bolt.fill"
        case "Snowy":
            return "cloud.snow.fill"
        case "Windy":
            return "wind"
        case "Foggy":
            return "cloud.fog.fill"
        default:
            // Handle SF Symbol names directly
            if weather.contains("sun.max.fill") { return "sun.max.fill" }
            if weather.contains("cloud.fill") { return "cloud.fill" }
            if weather.contains("cloud.rain.fill") { return "cloud.rain.fill" }
            if weather.contains("cloud.snow.fill") { return "cloud.snow.fill" }
            if weather.contains("wind") { return "wind" }
            if weather.contains("cloud.fog.fill") { return "cloud.fog.fill" }
            return "cloud"
        }
    }
    
    private func getWeatherColor() -> Color {
        if weather.isEmpty {
            return .gray
        }
        
        switch weather {
        case "Sunny":
            return .yellow
        case "Partly Cloudy":
            return .orange
        case "Cloudy":
            return .gray
        case "Rainy":
            return .blue
        case "Stormy":
            return Color(red: 0.4, green: 0.2, blue: 0.6) // Purple
        case "Snowy":
            return Color(red: 0.6, green: 0.8, blue: 1.0) // Light blue
        case "Windy":
            return .teal
        case "Foggy":
            return .gray.opacity(0.7)
        default:
            // Handle SF Symbol names directly
            if weather.contains("sun.max.fill") { return .yellow }
            if weather.contains("cloud.fill") { return .gray }
            if weather.contains("cloud.rain.fill") { return .blue }
            if weather.contains("cloud.snow.fill") { return Color(red: 0.6, green: 0.8, blue: 1.0) }
            if weather.contains("wind") { return .teal }
            if weather.contains("cloud.fog.fill") { return .gray.opacity(0.7) }
            return .gray
        }
    }
    
    private func getWeatherDescription(_ icon: String) -> String {
        switch icon {
        case "sun.max.fill": return "Sunny"
        case "cloud.fill": return "Cloudy"
        case "cloud.rain.fill": return "Rainy"
        case "cloud.snow.fill": return "Snowy"
        case "wind": return "Windy"
        case "cloud.fog.fill": return "Foggy"
        default: return "Weather"
        }
    }
}
