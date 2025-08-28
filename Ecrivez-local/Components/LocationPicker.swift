import SwiftUI
import MapKit

// MARK: - Supporting Models

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - LocationPickerView

struct LocationPickerView: View {
    @Binding var location: CLLocationCoordinate2D?
    @Binding var locationName: String?
    @Binding var locationLocality: String?
    let category: Category?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchViewModel = LocationSearchViewModel()
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }
    
    @State private var selectedMapItem: MKMapItem?

    private var selectedAnnotation: LocationAnnotation? {
        guard let coord = location else { return nil }
        return LocationAnnotation(
            coordinate: coord,
            title: locationName,
            subtitle: locationLocality
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with search
                headerView
                
                // Content based on device
                if isIPad {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(location == nil)
                }
            }
            .onAppear {
                setupInitialRegion()
            }
            .onReceive(searchViewModel.$shouldSelectCurrentLocation) { mapItem in
                if let mapItem = mapItem {
                    selectLocation(mapItem)
                    searchViewModel.shouldSelectCurrentLocation = nil
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Search bar
            searchBarView
            
            // Location selection area
            locationSelectionView
            
            // State indicators
            stateIndicatorView
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for a location", text: $searchViewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .submitLabel(.search)
                
                if !searchViewModel.searchText.isEmpty {
                    Button(action: { searchViewModel.clearSearch() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
    }
    
    @ViewBuilder
    private var locationSelectionView: some View {
        if let locationName = locationName {
            // When location is selected, show current location button and selected location in a row
            HStack(spacing: 12) {
                // Compact current location button
                Button(action: {
                    searchViewModel.requestCurrentLocation()
                }) {
                    HStack(spacing: 6) {
                        if searchViewModel.searchState == .searching && searchViewModel.searchText.isEmpty {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 16))
                        }
                        Text("Current")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .disabled(searchViewModel.permissionState == .denied || searchViewModel.permissionState == .restricted)
                
                // Selected location view
                selectedLocationCompactView
            }
        } else {
            // When no location selected, show full current location button
            currentLocationButton
        }
    }
    
    private var currentLocationButton: some View {
        Button(action: {
            searchViewModel.requestCurrentLocation()
        }) {
            HStack(spacing: 8) {
                if searchViewModel.searchState == .searching && searchViewModel.searchText.isEmpty {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "location.circle.fill")
                        .font(.title3)
                }
                Text("Use Current Location")
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .disabled(searchViewModel.permissionState == .denied || searchViewModel.permissionState == .restricted)
    }
    
    @ViewBuilder
    private var selectedLocationCompactView: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(locationName ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let locality = locationLocality {
                    Text(locality)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: clearSelection) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.green.opacity(0.3), lineWidth: 0.5)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    @ViewBuilder
    private var stateIndicatorView: some View {
        switch searchViewModel.searchState {
        case .searching:
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Searching...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .transition(.opacity)
            
        case .error(let message):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .transition(.opacity)
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Layout Views
    
    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            // Search results list (left side)
            searchResultsList
                .frame(width: 350)
            
            Divider()
            
            // Map (right side)
            mapView
        }
    }
    
    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            // Search results list - only show if there are results AND user is actively searching AND no location is selected
            if !searchViewModel.landmarks.isEmpty && (!searchViewModel.searchText.isEmpty || searchViewModel.searchState == .searching) && locationName == nil {
                searchResultsList
                    .frame(maxHeight: 250)
                
                Divider()
            }
            
            // Map
            mapView
                .frame(minHeight: 300)
        }
    }
    
    private var searchResultsList: some View {
        List(searchViewModel.landmarks, id: \.self) { mapItem in
            LocationResultRow(
                mapItem: mapItem,
                isSelected: selectedMapItem == mapItem
            ) {
                selectLocation(mapItem)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var mapView: some View {
        Group {
            if let annotation = selectedAnnotation {
                MapReader { mapProxy in
                    Map(coordinateRegion: $searchViewModel.region, annotationItems: [annotation]) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            CategoryMapPin(
                                category: category,
                                title: annotation.title,
                                isSelected: true
                            )
                        }
                    }
                    .onTapGesture { location in
                        handleMapTap(at: location, mapProxy: mapProxy)
                    }
                }
            } else {
                MapReader { mapProxy in
                    Map(coordinateRegion: $searchViewModel.region)
                        .onTapGesture { location in
                            handleMapTap(at: location, mapProxy: mapProxy)
                        }
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "map")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Search, tap on map, or use current location")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground).opacity(0.9))
                                    .shadow(radius: 5)
                            )
                        )
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func selectLocation(_ mapItem: MKMapItem) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedMapItem = mapItem
            location = mapItem.placemark.coordinate
            locationName = mapItem.name
            locationLocality = mapItem.placemark.locality
            
            // Update the map region to center on selected location
            searchViewModel.region.center = mapItem.placemark.coordinate
        }
    }
    
    private func clearSelection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedMapItem = nil
            location = nil
            locationName = nil
            locationLocality = nil
        }
    }
    
    private func setupInitialRegion() {
        if let existingLocation = location {
            searchViewModel.region = MKCoordinateRegion(
                center: existingLocation,
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
        }
    }
    
    private func handleMapTap(at location: CGPoint, mapProxy: MapProxy) {
        if let coordinate = mapProxy.convert(location, from: .local) {
            // Perform reverse geocoding for the tapped location
            let geocoder = CLGeocoder()
            let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            geocoder.reverseGeocodeLocation(clLocation) { [weak searchViewModel] placemarks, error in
                DispatchQueue.main.async {
                    if let placemark = placemarks?.first, error == nil {
                        let mkPlacemark = MKPlacemark(placemark: placemark)
                        let mapItem = MKMapItem(placemark: mkPlacemark)
                        
                        // Use intelligent naming strategy
                        if let name = placemark.name, !name.isEmpty {
                            mapItem.name = name
                        } else if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
                            mapItem.name = thoroughfare
                        } else if let locality = placemark.locality, !locality.isEmpty {
                            mapItem.name = locality
                        } else {
                            mapItem.name = "Selected Location"
                        }
                        
                        selectLocation(mapItem)
                    } else {
                        // Fallback to coordinate-based naming
                        let placemark = MKPlacemark(coordinate: coordinate)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                        selectLocation(mapItem)
                    }
                }
            }
        }
    }
}

// MARK: - LocationResultRow

private struct LocationResultRow: View {
    let mapItem: MKMapItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapItem.name ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = mapItem.placemark.title {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.green.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - CategoryMapPin

struct CategoryMapPin: View {
    let category: Category?
    let title: String?
    let isSelected: Bool
    
    @StateObject private var settingsManager = UserSettingsManager.shared
    
    private var pinColor: Color {
        if let category = category {
            return category.color
        } else {
            return colorFromString(settingsManager.settings.pinColor)
        }
    }
    
    private var pinSymbol: String {
        if let category = category, let symbol = category.symbol {
            return symbol
        } else {
            return settingsManager.settings.pinIcon
        }
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
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 4)
                
                Circle()
                    .fill(pinColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: pinSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            
            if let title = title {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                    )
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
    }
}
