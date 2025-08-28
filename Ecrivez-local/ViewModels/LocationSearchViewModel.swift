//
//  LocationSearchViewModel.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/3/24.
//

import SwiftUI
@preconcurrency import MapKit
import CoreLocation
import Combine

enum LocationPermissionState {
    case notDetermined
    case denied
    case authorized
    case restricted
}

enum LocationSearchState: Equatable {
    case idle
    case searching
    case success
    case error(String)
}

@MainActor
class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var landmarks: [MKMapItem] = []
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()
    @Published var searchState: LocationSearchState = .idle
    @Published var permissionState: LocationPermissionState = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var shouldSelectCurrentLocation: MKMapItem?
    
    private let locationManager = CLLocationManager()
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        locationManager.delegate = self
        setupDefaultRegion()
        setupSearchDebouncing()
        updatePermissionState()
    }
    
    private func setupDefaultRegion() {
        // Default to San Francisco
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
    }
    
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self?.performSearch()
                } else {
                    self?.landmarks = []
                    self?.searchState = .idle
                }
            }
            .store(in: &cancellables)
    }
    
    private func updatePermissionState() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            permissionState = .notDetermined
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        case .authorizedWhenInUse, .authorizedAlways:
            permissionState = .authorized
        @unknown default:
            permissionState = .notDetermined
        }
    }
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Cancel any existing search
        searchTask?.cancel()
        
        searchState = .searching
        
        searchTask = Task { [weak self] in
            guard let self = self else { return }
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = await self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            request.region = await self.region

            let search = MKLocalSearch(request: request)
            
            // Use the callback-based version to avoid Sendable issues
            search.start { [weak self] response, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        if !Task.isCancelled {
                            self.searchState = .error("Search failed: \(error.localizedDescription)")
                            self.landmarks = []
                        }
                    } else if let response = response {
                        if !Task.isCancelled {
                            self.landmarks = response.mapItems
                            self.searchState = response.mapItems.isEmpty ? .error("No locations found") : .success
                        }
                    }
                }
            }
        }
    }
    
    func requestCurrentLocation() {
        guard permissionState != .denied && permissionState != .restricted else {
            searchState = .error("Location access denied. Please enable location services in Settings.")
            return
        }
        
        if permissionState == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        searchState = .searching
        locationManager.requestLocation()
    }
    
    func clearSearch() {
        searchText = ""
        landmarks = []
        searchState = .idle
        searchTask?.cancel()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationSearchViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task { @MainActor in
            currentLocation = location
            
            // Update the region to center on current location
            region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            
            // Perform reverse geocoding to get proper location name
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    let mkPlacemark = MKPlacemark(placemark: placemark)
                    let mapItem = MKMapItem(placemark: mkPlacemark)
                    
                    // Use proper location naming strategy
                    if let name = placemark.name, !name.isEmpty {
                        mapItem.name = name
                    } else if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
                        mapItem.name = thoroughfare
                    } else if let locality = placemark.locality, !locality.isEmpty {
                        mapItem.name = locality
                    } else if let administrativeArea = placemark.administrativeArea, !administrativeArea.isEmpty {
                        mapItem.name = administrativeArea
                    } else {
                        mapItem.name = "My Location"
                    }
                    
                    landmarks = [mapItem]
                    searchState = .success
                    // Signal that this location should be automatically selected
                    shouldSelectCurrentLocation = mapItem
                }
            } catch {
                // Fallback to coordinate-based naming if geocoding fails
                let placemark = MKPlacemark(coordinate: location.coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
                
                landmarks = [mapItem]
                searchState = .success
                // Signal that this location should be automatically selected
                shouldSelectCurrentLocation = mapItem
            }
            // Don't set searchText to avoid triggering search
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            searchState = .error("Failed to get current location: \(error.localizedDescription)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            updatePermissionState()
        }
    }
}
