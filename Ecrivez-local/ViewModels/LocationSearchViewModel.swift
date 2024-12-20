//
//  LocationSearchViewModel.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/3/24.
//

import SwiftUI
import MapKit

@MainActor
class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var landmarks: [MKMapItem] = []
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()

    func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            // Since the class is @MainActor, no extra DispatchQueue.main.async is strictly needed.
            self.landmarks = response?.mapItems ?? []
        }
    }
}
