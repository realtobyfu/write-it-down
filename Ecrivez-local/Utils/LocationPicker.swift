import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var location: CLLocation? // Pass the binding to update CLLocation

    @StateObject private var viewModel = LocationSearchViewModel()
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        VStack {
            TextField("Search for a location", text: $viewModel.searchText, onEditingChanged: { _ in
                viewModel.updateSearchResults()
            })
            .padding(.vertical)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            List(viewModel.searchResults, id: \.self) { result in
                VStack(alignment: .leading) {
                    Text(result.title)
                        .font(.headline)
                    Text(result.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
                .onTapGesture {
                    selectLocation(result: result)
                }
            }
        }
        .navigationTitle("Pick a Location")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
            }
        }
    }

    private func selectLocation(result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let placemark = response?.mapItems.first?.placemark else {
                print("Location selection failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            // Update the binding with CLLocation
            location = CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
            presentationMode.wrappedValue.dismiss() // Dismiss the picker
        }
    }
}
