//
//  UserSettings.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI

struct UserSettings: Codable {
    // Map Settings
    var pinColor: String = "blue"
    var pinIcon: String = "map.pin"
    
    // Privacy & Security
    var defaultNotePrivacy: Bool = true // true = private, false = public
    var enableAnonymousPosting: Bool = false
    var enableLocationServices: Bool = true
    var dataRetentionDays: Int = 0 // 0 = forever
    
    // Notifications
    var enableDailyReminder: Bool = false
    var dailyReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    // List of available colors (still used for map pins)
    static let availableColors = ["blue", "green", "yellow", "red", "purple", "orange", "pink", "cyan", "indigo"]
    
    // List of available icons (still used for map pins)
    static let availableIcons = [
        "map.pin", "star", "flag", "heart", "leaf", "camera", "bell", "bookmark", "tag"
    ]
}

// UserSettings Manager for persistence
@MainActor
final class UserSettingsManager: ObservableObject {
    static let shared = UserSettingsManager()
    
    @Published var settings: UserSettings {
        didSet {
            save()
        }
    }
    
    private let userDefaultsKey = "userSettings"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = decodedSettings
        } else {
            self.settings = UserSettings()
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func reset() {
        settings = UserSettings()
    }
}
