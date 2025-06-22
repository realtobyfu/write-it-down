import SwiftUI
import MapKit
import CoreLocation

// LocationPickerView allows the user to search and select a location
// Enhancement for LocationPickerView
struct LocationPickerView: View {
    @Binding var location: CLLocationCoordinate2D?
    @Binding var locationName: String?
    @Binding var locationLocality: String?

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var searchViewModel = LocationSearchViewModel()
    @StateObject private var locationManager = LocationManager()
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Current Location Button
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                        Text("Use Current Location")
                            .foregroundColor(.blue)
                        Spacer()
                        if locationManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .disabled(locationManager.isLoading)
                .padding(.horizontal)
                
                // Clear Location Button
                if location != nil {
                    Button(action: {
                        location = nil
                        locationName = nil
                        locationLocality = nil
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Clear Location")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Search bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search for a location")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        TextField("Enter location name", text: $searchViewModel.searchText, onCommit: {
                            searchViewModel.search()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            searchViewModel.search()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(Circle().fill(Color.blue.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal)
                }

                // Selected location bubble
                if let locationName = locationName {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(locationName)
                            .font(.subheadline)
                        Spacer()
                    }
                        .padding(8)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // iPad-specific two-column layout
                if isIPad {
                    HStack(alignment: .top, spacing: 0) {
                        // List of search results (left column)
                        List(searchViewModel.landmarks, id: \.self) { mapItem in
                            Button(action: {
                                selectLocation(mapItem)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mapItem.name ?? "")
                                        .font(.headline)
                                    Text(mapItem.placemark.title ?? "")
                                        .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(width: 300)
                        .listStyle(PlainListStyle())
                        
                        // Map view (right column)
                        if let selectedLocation = location {
                            Map(coordinateRegion: $searchViewModel.region, annotationItems: [selectedLocation]) { coordinate in
                                MapPin(coordinate: coordinate)
                            }
                            .frame(minHeight: 500)
                            .cornerRadius(12)
                        } else {
                            // Default map
                            Map(coordinateRegion: $searchViewModel.region)
                                .frame(minHeight: 500)
                                .cornerRadius(12)
                                .overlay(
                                    Text("Search for a location")
                                        .padding()
                                        .background(Color(.systemBackground).opacity(0.8))
                                        .cornerRadius(8)
                                )
                        }
                    }
                } else {
                    // Original iPhone layout
                    List(searchViewModel.landmarks, id: \.self) { mapItem in
                        Button(action: {
                            selectLocation(mapItem)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mapItem.name ?? "")
                                    .font(.headline)
                                Text(mapItem.placemark.title ?? "")
                                    .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())

                    // Map view showing the selected location
                    if let selectedLocation = location {
                        Map(coordinateRegion: $searchViewModel.region, annotationItems: [selectedLocation]) { coordinate in
                            MapPin(coordinate: coordinate)
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitle("Select Location", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // Set the region to the selected location or default
                if let loc = location {
                    searchViewModel.region = MKCoordinateRegion(
                        center: loc,
                        latitudinalMeters: 1000,
                        longitudinalMeters: 1000
                    )
                } else {
                    // Default to a standard location if none is selected
                    searchViewModel.region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),  // San Francisco
                        latitudinalMeters: 10000,
                        longitudinalMeters: 10000
                    )
                }
                
                // Request location permission if not already granted
                locationManager.requestLocationPermission()
            }
            .onReceive(locationManager.$currentLocation) { newLocation in
                if let location = newLocation {
                    self.location = location.coordinate
                    
                    // Reverse geocode to get location name
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(location) { placemarks, error in
                        if let placemark = placemarks?.first {
                            DispatchQueue.main.async {
                                self.locationName = placemark.name ?? placemark.locality
                                self.locationLocality = placemark.locality
                                
                                // Update search region
                                searchViewModel.region = MKCoordinateRegion(
                                    center: location.coordinate,
                                    latitudinalMeters: 1000,
                                    longitudinalMeters: 1000
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func selectLocation(_ mapItem: MKMapItem) {
        location = mapItem.placemark.coordinate
        locationName = mapItem.name
        locationLocality = mapItem.placemark.locality
        searchViewModel.region.center = mapItem.placemark.coordinate
        searchViewModel.searchText = mapItem.name ?? ""
    }
}
