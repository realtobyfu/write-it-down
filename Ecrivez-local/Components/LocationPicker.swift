import SwiftUI
import MapKit

// LocationPickerView allows the user to search and select a location
// Enhancement for LocationPickerView
struct LocationPickerView: View {
    @Binding var location: CLLocationCoordinate2D?
    @Binding var locationName: String?
    @Binding var locationLocality: String?

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var searchViewModel = LocationSearchViewModel()
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }
    
    @State private var isCurrentLocationPressed = false
    @State private var searchResults: [MKMapItem] = []

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Search bar with current location button
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search for a location", text: $searchViewModel.searchText, onCommit: {
                                searchViewModel.search()
                            })
                            .submitLabel(.search)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        
                        Button(action: {
                            searchViewModel.search()
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Current location button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isCurrentLocationPressed = true
                        }
                        searchViewModel.requestCurrentLocation()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCurrentLocationPressed = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .font(.title3)
                            Text("Use Current Location")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                        .scaleEffect(isCurrentLocationPressed ? 0.95 : 1.0)
                    }
                }
                .padding(.top, isIPad ? 15 : 8)
                .padding(.bottom, 12)

                // Selected location bubble
                if let locationName = locationName {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3)
                        Text(locationName)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                    .padding(.horizontal)
                    .transition(.scale.combined(with: .opacity))
                }

                // iPad-specific two-column layout
                if isIPad {
                    HStack(alignment: .top, spacing: 0) {
                        // List of search results (left column)
                        List(searchViewModel.landmarks, id: \.self) { mapItem in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    location = mapItem.placemark.coordinate
                                    locationName = mapItem.name
                                    locationLocality = mapItem.placemark.locality
                                    searchViewModel.region.center = mapItem.placemark.coordinate
                                    searchViewModel.searchText = mapItem.name ?? ""
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mapItem.name ?? "")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(mapItem.placemark.title ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(width: 300)
                        .listStyle(InsetGroupedListStyle())
                        
                        // Map view (right column)
                        if let selectedLocation = location {
                            Map(coordinateRegion: $searchViewModel.region, annotationItems: [selectedLocation]) { coordinate in
                                MapPin(coordinate: coordinate)
                            }
                            .frame(minHeight: 500)
                        } else {
                            // Default map
                            Map(coordinateRegion: $searchViewModel.region)
                                .frame(minHeight: 500)
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
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                location = mapItem.placemark.coordinate
                                locationName = mapItem.name
                                locationLocality = mapItem.placemark.locality
                                searchViewModel.region.center = mapItem.placemark.coordinate
                                searchViewModel.searchText = mapItem.name ?? ""
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mapItem.name ?? "")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(mapItem.placemark.title ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(InsetGroupedListStyle())

                    // Map view showing the selected location
                    if let selectedLocation = location {
                        Map(coordinateRegion: $searchViewModel.region, annotationItems: [selectedLocation]) { coordinate in
                            MapPin(coordinate: coordinate)
                        }
                        .frame(height: 200)
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
            }
        }
    }
}
//
//extension CLLocationCoordinate2D: @retroactive Equatable, @retroactive Identifiable {
//    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
//        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
//    }
//    
//    public var id: String {
//        "\(latitude),\(longitude)"
//    }
//}
