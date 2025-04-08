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
//            Text(addressViewModel.address)
            Text(placeName)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
//        .onAppear {
//            addressViewModel.fetchAddress(from: location)
//        }
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

extension CLLocationCoordinate2D: @retroactive Identifiable {
    public var id: String {
        "\(latitude),\(longitude)"
    }
}

