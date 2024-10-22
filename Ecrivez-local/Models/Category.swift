//
//  Category.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import Foundation
import SwiftUI
import CoreData

extension Category {
    // Computed property to get the SwiftUI Color from colorName
    var color: Color {
        switch colorString ?? "" {
            case "green": return .green
            case "blue": return .blue
            case "yellow": return .yellow
            case "pink": return .pink
            case "brown": return .brown
            case "gray": return .gray
            case "red": return .red
            case "purple": return .purple
            case "orange": return .orange
            case "teal": return .teal
            case "indigo": return .indigo
            default: return .black
        }
    }
}
