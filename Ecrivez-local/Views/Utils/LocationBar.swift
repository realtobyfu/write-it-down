//
//  LocationBar.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/3/24.
//

import SwiftUI

struct LocationBar: View {
    var location: String

    var body: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.blue)
            Text(location)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    LocationBar(location: "Paris, France")
}
