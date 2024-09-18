//
// ImageSelectionView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI
import CoreLocation

struct LocationView: View {
    @Binding var location: CLLocation? // Make it a binding so it can be updated
    @State private var showingLocationPicker = false

    var body: some View {
        VStack {
            if let location = location {
                LocationBar(location: location)
                    .padding(.leading, 5)
                    .padding(.bottom, 25)
                    .fixedSize(horizontal: true, vertical: false)
            }

            Button(action: {
                showingLocationPicker.toggle()
            }) {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                    Text("Select Location")
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(location: $location)
            }
        }
    }
}
