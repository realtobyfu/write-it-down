//
//  LocationBar.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/3/24.
//

import SwiftUI
import CoreLocation

struct LocationBar: View {
    var location: CLLocation? // Accept CLLocation as input

    @State private var locationString: String = "Fetching location..." // State to store the human-readable location

    var body: some View {
        HStack {
            Text("📍")
                .font(.headline)
            Text(locationString) // Display the location string
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
        }
        .padding(4)
        .cornerRadius(30)
        .overlay(
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.blue, lineWidth: 1)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        )
        .padding(.horizontal, 10)
        .onAppear {
            // Reverse geocode the location when the view appears
            if let location = location {
                reverseGeocodeLocation(location)
            } else {
                locationString = "Location not available"
            }
        }
    }

    // Reverse geocode CLLocation to human-readable string
    private func reverseGeocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Error reverse geocoding location: \(error)")
                locationString = ""
            } else if let placemark = placemarks?.first {
                locationString = [
                    placemark.locality,
//                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
            } else {
                locationString = ""
            }
        }
    }
}

#Preview {
    LocationBar(location: CLLocation(latitude: 48.8566, longitude: 2.3522)) // Example for Paris
}
