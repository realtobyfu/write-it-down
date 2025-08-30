//
//  NotificationManager.swift
//  Write-It-Down
//
//  Created by Claude on 1/29/25.
//

import Foundation
@preconcurrency import UserNotifications
import SwiftUI

/// Centralized notification management system for Write-It-Down
/// 
/// **Engineering Decisions:**
/// 1. **Singleton Pattern**: Ensures consistent notification state across the app
/// 2. **UserNotifications Framework**: Modern iOS notification system with rich scheduling
/// 3. **Async/Await**: Clean permission handling and scheduling operations
/// 4. **ObservableObject**: SwiftUI integration for reactive UI updates
/// 
/// **Key Features:**
/// - Smart permission handling with graceful fallbacks
/// - Context-aware message selection based on time and user patterns
/// - Robust error handling and logging for production debugging
/// - Efficient scheduling that respects system limitations
///
final class NotificationManager: NSObject, ObservableObject, @unchecked Sendable {
    
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    var authorizationStatus: UNAuthorizationStatus = .notDetermined {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var isRequestingPermission = false {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Private Properties
    
    /// UserNotifications center for managing all notification operations
    /// **Design Choice**: Apple's recommended approach for iOS 10+ notification management
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Message provider for generating varied notification content
    /// **Architecture**: Separation of concerns - messaging logic isolated from scheduling
    private let messageProvider = NotificationMessageProvider()
    
    /// Identifier for our recurring daily notification
    /// **Rationale**: Consistent identifier allows us to replace/cancel specific notifications
    /// Format includes app identifier to avoid conflicts in shared notification space
    private let dailyReminderIdentifier = "com.tobiasfu.write-it-down.daily-reminder"
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        // **Critical Setup**: Assign delegate for handling notification interactions
        // This enables handling when user taps notifications while app is running
        notificationCenter.delegate = self
        
        // **Startup Optimization**: Check current permission status without blocking init
        updateAuthorizationStatusOnInit()
    }
    
    /// Simple authorization status check for initialization
    private func updateAuthorizationStatusOnInit() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async { [weak self] in
                self?.authorizationStatus = status
            }
        }
    }
    
    // MARK: - Permission Management
    
    /// Requests notification permission with comprehensive options
    func requestPermission(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.isRequestingPermission = true
        }
        
        let completionHandler = completion
        
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            // Update state on main thread
            DispatchQueue.main.async { [weak self] in
                self?.isRequestingPermission = false
                self?.updateAuthorizationStatusOnInit()
            }
            
            // Handle completion on background thread to avoid concurrency issues
            if let error = error {
                print("❌ NotificationManager: Permission request failed: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            
            if granted {
                print("✅ NotificationManager: Permission granted successfully")
            } else {
                print("⚠️ NotificationManager: Permission denied by user")
            }
            completionHandler(granted)
        }
    }
    
    
    // MARK: - Daily Reminder Management
    
    /// Schedules or updates the daily writing reminder
    func scheduleDailyReminder(at reminderTime: Date, isEnabled: Bool) {
        
        // **Step 1**: Always cancel existing notifications first
        cancelDailyReminder()
        
        // **Early Return**: If reminders are disabled, we're done after cancellation
        guard isEnabled else {
            print("📴 NotificationManager: Daily reminders disabled")
            return
        }
        
        // **Permission Check**: Verify we can actually send notifications
        hasPermission { [weak self] hasPermission in
            guard hasPermission else {
                print("⚠️ NotificationManager: Cannot schedule - no notification permission")
                return
            }
            
            self?.scheduleNotification(for: reminderTime)
        }
    }
    
    private func scheduleNotification(for reminderTime: Date) {
        // **Step 2**: Create notification content with smart message selection
        let content = UNMutableNotificationContent()
        
        // **Message Strategy**: Use varied, contextual messages to maintain user engagement
        let message = messageProvider.getDailyReminderMessage(for: reminderTime)
        content.body = message
        content.title = "Write-It-Down"
        content.sound = .default
        content.badge = 1
        
        // **Step 3**: Create scheduling trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // **Step 4**: Create and submit notification request
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ NotificationManager: Failed to schedule daily reminder: \(error.localizedDescription)")
            } else {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                let timeString = formatter.string(from: reminderTime)
                print("✅ NotificationManager: Daily reminder scheduled for \(timeString)")
                print("   Message: \(message)")
            }
        }
    }
    
    /// Cancels the daily reminder notification
    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        print("🗑️ NotificationManager: Daily reminder cancelled")
    }
    
    // MARK: - Helper Methods
    
    /// Checks if the app has permission to send notifications
    private func hasPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }
    
    /// Provides detailed notification permission status for debugging
    func getDetailedPermissionStatus(completion: @escaping (Bool, Bool, Bool, Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            completion(
                settings.authorizationStatus == .authorized,
                settings.alertSetting == .enabled,
                settings.soundSetting == .enabled,
                settings.badgeSetting == .enabled
            )
        }
    }
    
    /// Gets all pending notifications for debugging
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
    
    /// Forces an immediate test notification
    func sendTestNotification() {
        hasPermission { [weak self] hasPermission in
            guard hasPermission else {
                print("⚠️ NotificationManager: Cannot send test - no permission")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Write-It-Down"
            content.body = "Test notification - your daily reminders are working! 📝"
            content.sound = .default
            content.badge = 1
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "test-notification-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            self?.notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ NotificationManager: Test notification failed: \(error.localizedDescription)")
                } else {
                    print("✅ NotificationManager: Test notification sent")
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

/// Handles notification interactions when app is active
/// **Implementation**: Required for proper notification behavior in all app states
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Called when notification arrives while app is in foreground
    /// **Default Behavior**: iOS hides notifications when app is active
    /// **Override Purpose**: Show notifications even when app is open for better UX
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // **Presentation Strategy**: Show banner and sound even when app is active
        // **Reasoning**: Users should see writing reminders regardless of app state
        // **Options Explained**:
        // - .banner: Shows notification banner at top of screen
        // - .sound: Plays notification sound
        // - .badge: Updates app icon badge (handled by system)
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when user taps on a notification
    /// **Deep Linking**: Could navigate user directly to note creation
    /// **Analytics**: Track notification engagement for optimization
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        
        // **Badge Management**: Clear app badge when user interacts with notification
        /// **UX Standard**: Tapping notification should clear the red badge
        /// **User Expectation**: Notification interaction means "read"
        /// **iOS 17+ Compatible**: Use modern UNUserNotificationCenter API
        /// **Thread Safety**: Delegate methods run on main thread by default
        
        // **Safe Badge Clearing**: Simple approach without complex concurrency
        if #available(iOS 16.0, *) {
            Task {
                try? await notificationCenter.setBadgeCount(0)
            }
        } else {
            // Fire and forget for older iOS
            notificationCenter.setBadgeCount(0) { _ in }
        }
        
        // **Action Handling**: Different responses based on notification type
        if identifier == dailyReminderIdentifier {
            print("📝 NotificationManager: User tapped daily reminder notification")
            
            // **Future Enhancement**: Could post notification to open note composer
            // NotificationCenter.default.post(name: .openNoteComposer, object: nil)
            
            // **Analytics Opportunity**: Track how often users engage with reminders
            // This helps optimize timing and message content
        }
        
        print("🔄 NotificationManager: Badge cleared after notification interaction")
        
        // **iOS Requirement**: Must call completion handler
        completionHandler()
    }
}
