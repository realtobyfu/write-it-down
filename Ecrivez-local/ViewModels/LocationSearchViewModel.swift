//
//  LocationSearchViewModel.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/3/24.
//

import SwiftUI
import MapKit
import CoreLocation

@MainActor
class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var landmarks: [MKMapItem] = []
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()
    
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }
    
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
    
    func requestCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationSearchViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task { @MainActor in
            // Update the region to center on current location
            region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            
            // Create a map item for current location
            let placemark = MKPlacemark(coordinate: location.coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = "Current Location"
            
            // Add to landmarks
            landmarks = [mapItem]
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
