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
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
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
                    HStack(spacing: 8) {
                        Image(systemName: selectedDate != nil ? "calendar.badge.checkmark" : "calendar")
                            .font(.title3)
                            .foregroundColor(selectedDate != nil ? .blue : .gray)
                        if let date = selectedDate {
                            Text(date, style: .date)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(selectedDate != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .scaleEffect(isDatePressed ? 0.95 : 1.0)
                }
                
                // Location button
                Button(action: {
                    if premiumManager.hasAccess(to: .locationTagging) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLocationPressed.toggle()
                        }
                        showingLocationPicker = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isLocationPressed = false
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: location != nil ? "location.fill" : "location")
                            .font(.title3)
                            .foregroundColor(location != nil ? .green : .gray)
                        if let name = locationName {
                            Text(name)
                                .font(.body)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(location != nil ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .scaleEffect(isLocationPressed ? 0.95 : 1.0)
                }
                .disabled(!premiumManager.hasAccess(to: .locationTagging))
                
                // Weather button
                Button(action: {
                    if premiumManager.hasAccess(to: .weatherTagging) {
                        showingWeatherPicker = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: weather.isEmpty ? "cloud" : weather)
                        if !weather.isEmpty {
                            Text(getWeatherDescription(weather))
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!weather.isEmpty ? Color.orange.opacity(0.2) : Color(.systemGray6))
                    .cornerRadius(16)
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
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                }
                .disabled(!premiumManager.hasAccess(to: .imageInsertion))
                
                Spacer()
            }
            .padding(.horizontal)
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