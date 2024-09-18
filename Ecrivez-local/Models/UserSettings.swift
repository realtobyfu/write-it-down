//
//  UserSettings.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct UserSettings: Codable {
    var pinColor: String = "blue" // Default color
    var pinIcon: String = "map.pin" // Default SF Symbol icon
    
    // List of available colors
    static let availableColors = ["blue", "green", "yellow", "red", "purple", "orange"]

    // List of available icons
    static let availableIcons = [
        "map.pin", "star", "flag", "heart", "leaf", "camera"
    ]
}
