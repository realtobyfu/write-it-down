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
    
    // Editor Preferences
    var defaultFontSize: CGFloat = 16
    var defaultFontName: String = "System"
    var defaultNoteType: String = "note"
    var defaultNoteColor: String = "blue"
    var defaultNoteSymbol: String = "note.text"
    var autoSaveInterval: TimeInterval = 30 // seconds
    var showRichTextToolbar: Bool = true
    
    // Privacy & Security
    var defaultNotePrivacy: Bool = true // true = private, false = public
    var enableAnonymousPosting: Bool = false
    var enableLocationServices: Bool = true
    var dataRetentionDays: Int = 0 // 0 = forever
    
    // Appearance
    var appTheme: String = "system" // system, light, dark
    var noteListDensity: String = "standard" // compact, standard, comfortable
    var showNotePreview: Bool = true
    var previewLineCount: Int = 3
    
    // Notifications
    var enableSyncNotifications: Bool = true
    var enableDailyReminder: Bool = false
    var dailyReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var enableSocialNotifications: Bool = true
    
    // Export Settings
    var defaultExportFormat: String = "rtf" // rtf, pdf, txt
    var includeMetadataInExport: Bool = true
    var includeImagesInExport: Bool = true
    
    // List of available colors
    static let availableColors = ["blue", "green", "yellow", "red", "purple", "orange", "pink", "cyan", "indigo"]
    
    // List of available icons
    static let availableIcons = [
        "map.pin", "star", "flag", "heart", "leaf", "camera", "bell", "bookmark", "tag"
    ]
    
    // Available fonts
    static let availableFonts = [
        "System", "Helvetica Neue", "Arial", "Times New Roman", "Georgia", "Courier New", "Verdana", "Avenir", "Menlo"
    ]
    
    // Available themes
    static let availableThemes = ["system", "light", "dark"]
    
    // Available densities
    static let availableDensities = ["compact", "standard", "comfortable"]
    
    // Available export formats
    static let availableExportFormats = ["rtf", "pdf", "txt", "markdown"]
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
