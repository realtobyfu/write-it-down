//
//  LocationAddressViewModel.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 11/17/24.
//
import SwiftUI
import CoreLocation

@MainActor
class LocationAddressViewModel: ObservableObject {
    @Published var address: String = ""

    func fetchAddress(from location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let cllocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(cllocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            self.address = placemarks?.first.map {
                [$0.name, $0.locality, $0.administrativeArea, $0.country]
                .compactMap { $0 }
                .joined(separator: ", ")
            } ?? "Unknown location"
        }
    }
}
