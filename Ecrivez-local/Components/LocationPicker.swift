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

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                // Search bar
                HStack {
                    TextField("Search for a location", text: $searchViewModel.searchText, onCommit: {
                        searchViewModel.search()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)

                    Button(action: {
                        searchViewModel.search()
                    }) {
                        Text("Search")
                    }
                    .padding(.trailing)
                }
                .padding(.top, isIPad ? 15 : 8)

                // Selected location bubble
                if let locationName = locationName {
                    Text("📍 \(locationName)")
                        .padding(8)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // iPad-specific two-column layout
                if isIPad {
                    HStack(alignment: .top, spacing: 0) {
                        // List of search results (left column)
                        List(searchViewModel.landmarks, id: \.self) { mapItem in
                            Button(action: {
                                location = mapItem.placemark.coordinate
                                locationName = mapItem.name
                                locationLocality = mapItem.placemark.locality
                                searchViewModel.region.center = mapItem.placemark.coordinate
                                searchViewModel.searchText = mapItem.name ?? ""
                            }) {
                                VStack(alignment: .leading) {
                                    Text(mapItem.name ?? "")
                                        .font(.headline)
                                    Text(mapItem.placemark.title ?? "")
                                        .font(.subheadline)
                                }
                            }
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
                            location = mapItem.placemark.coordinate
                            locationName = mapItem.name
                            locationLocality = mapItem.placemark.locality
                            searchViewModel.region.center = mapItem.placemark.coordinate
                            searchViewModel.searchText = mapItem.name ?? ""
                        }) {
                            VStack(alignment: .leading) {
                                Text(mapItem.name ?? "")
                                    .font(.headline)
                                Text(mapItem.placemark.title ?? "")
                                    .font(.subheadline)
                            }
                        }
                    }

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
