//
//  MapView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/3/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    @Binding var coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Map(coordinateRegion: Binding(
            get: {
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
            },
            set: { newRegion in
                coordinate = newRegion.center
            }
        ))
        .ignoresSafeArea(edges: .top)
        .frame(height: 300)
    }
}
