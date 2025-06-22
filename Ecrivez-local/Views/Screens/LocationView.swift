//
// LocationSelectionBar.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationSelectionBar: View {
    var location: CLLocationCoordinate2D
    let placeName: String
    @StateObject private var addressViewModel = LocationAddressViewModel()
    
    var body: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(.purple)
            // Display the placeName which will already have the landmark vs locality logic applied
            Text(placeName)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}
struct LocationView: View {
    @Binding var location: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion

    init(location: Binding<CLLocationCoordinate2D>) {
        _location = location
        _region = State(initialValue: MKCoordinateRegion(
            center: location.wrappedValue,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        ))
    }

    var body: some View {
        VStack {
            Text("Location")
                .font(.headline)
            
            Map(coordinateRegion: $region, annotationItems: [location]) { item in
                MapPin(coordinate: item)
            }
            
            .onChange(of: region.center) { newCenter in
                location = newCenter
            }
        }
        .frame(height: 200)
        .cornerRadius(10)
        .padding()
    }
}

// Extend CLLocationCoordinate2D to conform to Identifiable and Equatable for Map annotation and onChange
extension CLLocationCoordinate2D: Identifiable, Equatable {
    public var id: String { "\(latitude),\(longitude)" }
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
