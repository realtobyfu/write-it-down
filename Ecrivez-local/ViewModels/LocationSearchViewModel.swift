//
//  LocationSearchViewModel.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/3/24.
//

import SwiftUI
import MapKit

import SwiftUI
import MapKit

class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var landmarks: [MKMapItem] = []
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()

    func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                DispatchQueue.main.async {
                    self.landmarks = response.mapItems
                }
            } else {
                print("Error searching for landmarks: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
