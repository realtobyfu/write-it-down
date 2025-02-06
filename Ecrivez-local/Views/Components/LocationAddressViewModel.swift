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
    @Published var address: String = "Loading..."
    
    func fetchAddress(from coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            // If no placemarks or there's an error, show "Unknown"
            guard let placemark = placemarks?.first, error == nil else {
                DispatchQueue.main.async {
                    self.address = "Unknown"
                }
                return
            }
            
            // Extract city, state, and country; handle nil values gracefully
            let city = placemark.locality ?? "City"
            let state = placemark.administrativeArea ?? "State"
            let country = placemark.country ?? "Country"
            
            // Combine them into a single string
            let combinedAddress = "\(city), \(state), \(country)"
            
            // Update published property on main thread
            DispatchQueue.main.async {
                self.address = combinedAddress
            }
        }
    }
}
