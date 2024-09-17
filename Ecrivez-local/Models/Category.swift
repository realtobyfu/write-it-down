//
//  Category.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct Category: Hashable, Codable {
    var symbol: String
    var colorName: String

    var color: Color {
        switch colorName {
        case "green":
            return .green
        case "blue":
            return .blue
        case "yellow":
            return .yellow
        case "pink":
            return .pink
        case "brown":
            return .brown
        case "gray":
            return .gray
        default:
            return .white
        }
    }
}
