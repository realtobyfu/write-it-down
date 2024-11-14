import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var selectedLocation: CLLocation?
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchViewModel = LocationSearchViewModel()
    @State private var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var body: some View {
        VStack {
            // Map View
            MapView(coordinate: $coordinate)
                .onAppear {
                    if let userLocation = locationManager.location?.coordinate {
                        coordinate = userLocation
                        searchViewModel.region = MKCoordinateRegion(
                            center: userLocation,
                            latitudinalMeters: 1000,
                            longitudinalMeters: 1000
                        )
                        searchViewModel.search()
                    } else {
                        // Provide a default coordinate
                        coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco
                    }
                }
                .onChange(of: coordinate) { newCoordinate in
                    searchViewModel.region.center = newCoordinate
                    searchViewModel.search()
                    // Syncing selectedLocation with coordinate if needed
                    selectedLocation = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
                }
            
            // Search Bar
            HStack {
                TextField("Search for a place", text: $searchViewModel.searchText, onCommit: {
                    searchViewModel.search()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            }
            
            // List of Locations
            List(searchViewModel.landmarks, id: \.self) { landmark in
                VStack(alignment: .leading) {
                    Text(landmark.name ?? "")
                        .font(.headline)
                    Text(landmark.placemark.title ?? "")
                        .font(.subheadline)
                }
                .onTapGesture {
                    // Update selected location and coordinate
                    if let location = landmark.placemark.location {
                        selectedLocation = location
                        coordinate = location.coordinate
                    }
                }
            }
        }
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
