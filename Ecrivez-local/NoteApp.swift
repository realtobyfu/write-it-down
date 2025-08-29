//
//  Ecrivez_localApp.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 7/22/24.
//
import SwiftUI
import CoreData
import UserNotifications

@main
struct NoteApp: App {
    // at the root level, define the behaviors for when app is opened again
    // if auth screen is still open -> dismiss it
    // optional: show a message indicating the user is logged in
    // go to the home screen
    @StateObject private var dataController = CoreDataManager()
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    
    /// **User Settings**: App-wide preferences and customizations
    /// **Integration**: Manages notification preferences and other user settings
    @StateObject private var settingsManager = UserSettingsManager.shared
    
    /// **Dark Mode**: System-wide theme preference
    /// **Binding**: Directly bound to system preference for immediate updates
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    /// **Onboarding**: Track whether user has completed initial setup
    /// **First Launch**: Determines whether to show onboarding vs. main app
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // TEMPORARY: Reset onboarding for testing
//    UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

    @State private var showDonationView = false
    
    @AppStorage("appOpenCount") private var appOpenCount = 0

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                ContentView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .environmentObject(authVM)
                    .environmentObject(dataController)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                
                    .onOpenURL { url in
                        Task {
                            await handleURL(url: url)
                        }
                    }
                    .task {
                        // **App Launch Sequence**: Critical initialization tasks in optimal order
                        /// **Timing**: Fast operations first, then network-dependent operations
                        
                        // **1. Authentication Check**: Restore existing session if available
                        /// **Priority**: High - affects data sync and user experience
                        /// **Performance**: Local check, minimal delay
                        await authVM.checkIsAuthenticated()
                        
                        // **2. Database Health**: Ensure local data integrity
                        /// **Risk Mitigation**: Catch data corruption issues early
                        /// **Recovery**: Allows graceful degradation if database issues detected
                        let isHealthy = dataController.checkDatabaseHealth()
                        if !isHealthy {
                            print("WARNING: Database health check failed on app launch")
                        }
                        
                        // **3. Data Cleanup**: Remove duplicate categories (data integrity)
                        /// **Background Task**: Non-blocking operation for data quality
                        /// **Error Handling**: Graceful failure - doesn't block app launch
                        do {
                            try await SyncManager.shared.cleanupDuplicateCategories(context: dataController.container.viewContext)
                        } catch {
                            print("Failed to cleanup duplicate categories: \(error)")
                        }
                        
                        // **4. Notification Setup**: Initialize daily writing reminders
                        /// **User Engagement**: Critical for building writing habits
                        /// **Smart Defaults**: Uses user's saved preferences for scheduling
                        /// **Permission Handling**: Gracefully handles denied permissions
                        setupNotifications()
                        
                        // **4.5. Clear App Badge**: Reset notification badge when app launches
                        /// **UX Fix**: Remove persistent red badge from app icon
                        /// **User Expectation**: Opening the app should clear notification badges
                        clearAppBadge()
                        
                        // **5. Cloud Sync**: Sync data if user is authenticated
                        /// **Data Consistency**: Keep local and cloud data synchronized
                        /// **Conditional**: Only runs if user has sync enabled and is logged in
                        if authVM.isAuthenticated && SyncManager.shared.syncEnabled {
                            await SyncManager.shared.performAutoSync(context: dataController.container.viewContext)
                        }
                        
                        // **6. Analytics**: Track app usage for engagement metrics
                        appOpenCount += 1
                        
                        // **7. Monetization**: Show donation prompt at strategic intervals
                        /// **Strategy**: After user has experienced app value (4+ opens)
                        /// **Frequency**: Every 10 opens to avoid being intrusive
                        if appOpenCount == 4 || (appOpenCount >= 0 && appOpenCount % 10 == 0){
                            // **UX Delay**: Let user settle into app before showing donation prompt
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showDonationView = true
                            }
                        }
                    }
                    .onChange(of: authVM.isAuthenticated) { oldValue, newValue in
                        // Trigger sync when user becomes authenticated
                        if !oldValue && newValue && SyncManager.shared.syncEnabled {
                            Task {
                                await SyncManager.shared.performAutoSync(context: dataController.container.viewContext)
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - URL Handling
    
    /// **Deep Link Handler**: Processes authentication callbacks and other URL schemes
    /// **Usage**: Called when app is opened via custom URL (e.g., from email magic links)
    func handleURL(url: URL) async {
        // **Security Check**: Ensure URL scheme matches our app's registered scheme
        /// **Protection**: Prevents processing malicious URLs from other sources
        /// **Bundle ID Match**: Scheme must match exactly for security
        guard url.scheme == "com.tobiasfu.write-it-down" else {
            print("Received unsupported URL scheme.")
            return
        }
        
        do {
            // **Authentication Flow**: Parse session data from Supabase auth callback
            /// **Magic Link**: Handles email-based authentication completion
            /// **Session Management**: Establishes authenticated session in app
            try await SupabaseManager.shared.client.auth.session(from: url)
            authVM.didCompleteSignIn()
        } catch {
            print("Failed to parse session: \(error)")
        }
    }
    
    // MARK: - Notification Setup
    
    /// **Notification Initialization**: Set up daily writing reminders based on user preferences
    /// **Smart Defaults**: New users get reminders enabled at optimal time (7 PM)
    /// **Existing Users**: Respects their saved preferences and schedules accordingly
    /// **Permission Strategy**: Non-intrusive permission requests with graceful fallbacks
    private func setupNotifications() {
        let settings = settingsManager.settings
        
        // **Permission Check**: Only proceed if notifications should be enabled
        /// **User Choice**: Respects user's notification preference setting
        /// **Early Return**: Avoid unnecessary work if notifications disabled
        guard settings.enableDailyReminder else {
            print("📴 NoteApp: Daily reminders disabled by user preference")
            return
        }
        
        // **Permission Strategy**: Check current status before requesting
        /// **UX Consideration**: Don't spam permission requests
        /// **State Management**: Let NotificationManager handle permission logic
        let currentStatus = notificationManager.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            // **First Time**: Request permissions with clear value proposition
            /// **Timing**: During app setup when user is most engaged
            /// **Context**: User has already enabled reminders in settings
            print("📱 NoteApp: Requesting notification permissions for first time")
            
            notificationManager.requestPermission { granted in
                if granted {
                    // **Success Path**: Schedule the reminder immediately
                    self.scheduleUserReminder()
                } else {
                    print("⚠️ NoteApp: Notification permission denied, reminders won't work")
                }
            }
            
        case .authorized:
            // **Already Granted**: Just schedule the reminder
            /// **Efficiency**: Skip permission checks and go straight to scheduling
            scheduleUserReminder()
            
        case .denied:
            // **Previously Denied**: Log for debugging but don't pester user
            /// **Respect Choice**: User explicitly denied, don't keep asking
            /// **Logging**: Track for analytics on permission denial rates
            print("⚠️ NoteApp: Notifications denied, cannot schedule reminders")
            
        case .provisional, .ephemeral:
            // **Limited Permissions**: Try to schedule anyway, might work partially
            /// **iOS Feature**: Some notification types may still work
            scheduleUserReminder()
            
        @unknown default:
            // **Future Compatibility**: Handle any new states Apple might add
            print("❓ NoteApp: Unknown notification permission state")
            scheduleUserReminder()
        }
    }
    
    /// **Reminder Scheduling**: Actually schedule the daily notification based on user settings
    /// **Smart Messaging**: Uses time-aware message selection for better engagement
    private func scheduleUserReminder() {
        let settings = settingsManager.settings
        
        // **Schedule Notification**: Use user's preferred time and enable status
        /// **Real-time Settings**: Always uses current user preferences
        /// **Smart Messages**: NotificationManager handles message rotation automatically
        notificationManager.scheduleDailyReminder(
            at: settings.dailyReminderTime,
            isEnabled: settings.enableDailyReminder
        )
        
        // **Success Logging**: Confirm reminder is set up for debugging
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: settings.dailyReminderTime)
        print("✅ NoteApp: Daily writing reminder scheduled for \(timeString)")
    }
    
    /// **Badge Management**: Clear app icon badge when user opens the app
    /// **UX Improvement**: Removes persistent red badge that confuses users
    /// **iOS Standard**: Most apps clear badges when opened
    private func clearAppBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("⚠️ NoteApp: Failed to clear badge: \(error.localizedDescription)")
            } else {
                print("🔄 NoteApp: App badge cleared")
            }
        }
    }
}
