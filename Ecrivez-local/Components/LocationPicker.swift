import SwiftUI
import MapKit

// LocationPickerView allows the user to search and select a location
struct LocationPickerView: View {
    @Binding var location: CLLocationCoordinate2D?
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var searchViewModel = LocationSearchViewModel()

    var body: some View {
        NavigationView {
            VStack {
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

                // List of search results
                List(searchViewModel.landmarks, id: \.self) { mapItem in
                    Button(action: {
                        location = mapItem.placemark.coordinate
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

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
