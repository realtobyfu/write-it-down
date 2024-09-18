//
//  Untitled.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct FormattingToolbar: View {
    var toggleBold: () -> Void
    var toggleItalic: () -> Void
    var addBulletPoint: () -> Void

    var body: some View {
        HStack {
            Button(action: toggleBold) {
                Image(systemName: "bold")
            }
            .padding(.horizontal)

            Button(action: toggleItalic) {
                Image(systemName: "italic")
            }
            .padding(.horizontal)

            Button(action: addBulletPoint) {
                Image(systemName: "list.bullet")
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }
}


