//
// ImageSelectionView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct ImageSelectionView: View {
    var selectedImages: [UIImage]

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(selectedImages, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .padding()
                }
            }
        }
    }
}
