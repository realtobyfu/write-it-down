//
//  Category.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI
import uuid

struct Category: Hashable, Codable, Identifiable {
    var id = UUID()
    var symbol: String
    var colorName: String
//    var name: String

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
        case "red":
            return .red
        case "purple":
            return .purple
        case "orange":
            return .orange
        case "teal":
            return .teal
        case "indigo":
            return .indigo
        default:
            return .white
        }
    }
}
