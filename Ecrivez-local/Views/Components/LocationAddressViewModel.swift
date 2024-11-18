//
//  LocationAddressViewModel.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 11/17/24.
//
import SwiftUI
import CoreLocation

class LocationAddressViewModel: ObservableObject {
    @Published var address: String = ""

    func fetchAddress(from location: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let cllocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(cllocation) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.address = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country].compactMap { $0 }.joined(separator: ", ")
                }
            } else {
                DispatchQueue.main.async {
                    self.address = "Unknown location"
                }
            }
        }
    }
}
