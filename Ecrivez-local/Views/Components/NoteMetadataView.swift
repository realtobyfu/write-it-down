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
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Date button
                Button(action: {
                    if selectedDate == nil {
                        selectedDate = Date()
                    } else {
                        selectedDate = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: selectedDate != nil ? "calendar.badge.checkmark" : "calendar")
                        if let date = selectedDate {
                            Text(date, style: .date)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedDate != nil ? Color.blue.opacity(0.2) : Color(.systemGray6))
                    .cornerRadius(16)
                }
                
                // Location button
                Button(action: {
                    if premiumManager.hasAccess(to: .locationTagging) {
                        showingLocationPicker = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: location != nil ? "location.fill" : "location")
                        if let name = locationName {
                            Text(name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(location != nil ? Color.green.opacity(0.2) : Color(.systemGray6))
                    .cornerRadius(16)
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