//
//  Category.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import Foundation
import SwiftUI
// Extension on Category to use the centralized color mapping
extension Category {
    // Replace the existing computed property with this
    var color: Color {
        return StyleManager.color(from: colorString ?? "")
    }
}

