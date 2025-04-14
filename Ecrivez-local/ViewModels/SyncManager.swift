//
//  StyleManager.swift
//  Write-It-Down
//
//  Created on 4/9/25.
//

import SwiftUI

/// A centralized utility for managing app-wide styling elements like colors and symbols
struct StyleManager {
    
    // MARK: - Colors
    
    /// All available category colors with their string identifiers
    static let availableColors: [String] = [
        "green", "blue", "yellow", "pink", "brown",
        "gray", "red", "purple", "orange", "teal", "indigo",
        // New colors you might want to add:
        "mint", "cyan", "rose", "lightBlue", "darkGreen"
    ]
    
    /// Maps color string identifiers to SwiftUI Color objects
    static func color(from identifier: String) -> Color {
        switch identifier {
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
        // New colors you might want to add:
        case "mint": return .mint
        case "cyan": return .cyan
        case "rose": return Color(red: 0.98, green: 0.33, blue: 0.42)
        case "lightBlue": return Color(red: 0.68, green: 0.85, blue: 0.9)
        case "darkGreen": return Color(red: 0.0, green: 0.5, blue: 0.0)
        default: return .black
        }
    }
    
    // MARK: - Symbols
    
    /// All available category symbols
    static let availableSymbols: [String] = [
        "book", "fork.knife", "sun.min", "movieclapper",
        "message.badge.filled.fill", "list.bullet", "paperplane",
        // New symbols you might want to add:
        "doc.text", "calendar", "brain.head.profile",
        "lightbulb", "quote.bubble", "music.note",
        "cart", "tag", "house", "heart", "star"
    ]
    
    // MARK: - Category Templates
    
    /// Default categories for new users
    static let defaultCategories: [(symbol: String, color: String, name: String)] = [
        ("book", "green", "Book"),
        ("fork.knife", "blue", "Cooking"),
        ("sun.min", "yellow", "Day"),
        ("movieclapper", "pink", "Movie"),
        ("message.badge.filled.fill", "brown", "Message"),
        ("list.bullet", "gray", "List"),
    ]
}

// Extension for background color in PublicNoteDetailView and PublicNoteView
extension SupabaseNote {
    var backgroundColor: Color {
        return StyleManager.color(from: colorString)
    }
}
