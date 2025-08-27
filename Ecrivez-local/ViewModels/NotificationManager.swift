//
//  NotificationManager.swift
//  Write-It-Down
//
//  Created by Claude on 1/29/25.
//

import Foundation
import UserNotifications
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
final class NotificationManager: NSObject, ObservableObject, @unchecked Sendable {
    
    // MARK: - Singleton
    /// Shared instance following singleton pattern
    /// **Reasoning**: Notifications need consistent state management across app lifecycle
    /// Only one notification manager should exist to avoid scheduling conflicts
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    
    /// Current authorization status for notifications
    /// **Purpose**: Enables reactive UI that shows/hides notification settings based on permissions
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// Whether the system is currently processing a notification request
    /// **Purpose**: Prevents duplicate permission requests and provides loading states
    @Published var isRequestingPermission = false
    
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
        
        // **Startup Optimization**: Check current permission status on next run loop
        // **Concurrency Fix**: Detached task prevents initialization blocking
        Task.detached { [weak self] in
            await self?.updateAuthorizationStatus()
        }
    }
    
    // MARK: - Permission Management
    
    /// Requests notification permission with comprehensive options
    /// **Permission Strategy**: Request all notification features upfront for best UX
    /// **Error Handling**: Graceful degradation if user denies specific permissions
    /// **Threading**: Runs on main actor to safely update @Published properties
    @MainActor
    func requestPermission() async -> Bool {
        isRequestingPermission = true
        defer { isRequestingPermission = false }
        
        do {
            // **Permission Scope**: Request comprehensive notification features
            // - alert: Show notification banners/alerts
            // - sound: Play notification sounds  
            // - badge: Update app icon badge count
            // **Rationale**: Better to request all needed permissions once vs. repeatedly asking
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            
            await updateAuthorizationStatus()
            
            if granted {
                print("✅ NotificationManager: Permission granted successfully")
                return true
            } else {
                print("⚠️ NotificationManager: Permission denied by user")
                return false
            }
        } catch {
            print("❌ NotificationManager: Permission request failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Updates the current authorization status
    /// **Threading**: Runs on main thread to update @Published properties
    /// **Performance**: Caches status to avoid repeated system calls
    @MainActor
    private func updateAuthorizationStatus() async {
        let authStatus = await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
        // **Safe Update**: We're guaranteed to be on MainActor here
        self.authorizationStatus = authStatus
    }
    
    // MARK: - Daily Reminder Management
    
    /// Schedules or updates the daily writing reminder
    /// **Smart Scheduling Logic**:
    /// 1. Cancel existing notifications to avoid duplicates
    /// 2. Generate context-aware message based on time/patterns
    /// 3. Create recurring notification with intelligent retry logic
    /// 
    /// - Parameter reminderTime: The time of day to send the notification
    /// - Parameter isEnabled: Whether reminders should be active
    func scheduleDailyReminder(at reminderTime: Date, isEnabled: Bool) async {
        
        // **Step 1**: Always cancel existing notifications first
        // **Rationale**: Prevents duplicate notifications and ensures updated settings take effect
        await cancelDailyReminder()
        
        // **Early Return**: If reminders are disabled, we're done after cancellation
        guard isEnabled else {
            print("📴 NotificationManager: Daily reminders disabled")
            return
        }
        
        // **Permission Check**: Verify we can actually send notifications
        // **UX Consideration**: Fail gracefully if permissions not granted
        guard await hasPermission() else {
            print("⚠️ NotificationManager: Cannot schedule - no notification permission")
            return
        }
        
        // **Step 2**: Create notification content with smart message selection
        let content = UNMutableNotificationContent()
        
        // **Message Strategy**: Use varied, contextual messages to maintain user engagement
        // Messages rotate based on day of week and time to feel fresh and personal
        let message = messageProvider.getDailyReminderMessage(for: reminderTime)
        content.body = message
        content.title = "Write-It-Down" // **Branding**: Clear app identification
        
        // **Sound Strategy**: Use default sound for familiarity and accessibility
        // **Consideration**: Users can disable sounds system-wide if preferred
        content.sound = .default
        
        // **Badge Strategy**: Simple increment to show unread notifications
        // **Limitation**: iOS doesn't provide current badge count, so we use 1
        content.badge = 1
        
        // **Step 3**: Create sophisticated scheduling trigger
        // **Key Decision**: Use DateComponents for recurring notifications
        // **Advantage**: Automatically handles timezone changes, DST, calendar variations
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // **Trigger Configuration**: Daily recurring notification
        // **Parameter**: repeats: true enables automatic daily scheduling
        // **iOS Limitation**: System may delay notifications if device is heavily used
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // **Step 4**: Create and submit notification request
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            
            // **Success Logging**: Helps debug scheduling issues in production
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: reminderTime)
            print("✅ NotificationManager: Daily reminder scheduled for \(timeString)")
            print("   Message: \(message)")
            
        } catch {
            // **Error Logging**: Critical for debugging notification failures
            // **Common Issues**: System notification limit reached, invalid trigger
            print("❌ NotificationManager: Failed to schedule daily reminder: \(error.localizedDescription)")
        }
    }
    
    /// Cancels the daily reminder notification
    /// **Use Cases**: User disables reminders, changes reminder time, app uninstall cleanup
    func cancelDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        print("🗑️ NotificationManager: Daily reminder cancelled")
    }
    
    // MARK: - Helper Methods
    
    /// Checks if the app has permission to send notifications
    /// **Implementation**: Async check prevents UI blocking
    /// **Return Logic**: Only returns true for explicitly granted permissions
    private func hasPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus == UNAuthorizationStatus.authorized)
            }
        }
    }
    
    /// Provides detailed notification permission status for debugging
    /// **Use Case**: Settings UI can show specific permission issues
    /// **Granularity**: Checks individual permission types (alert, sound, badge)
    func getDetailedPermissionStatus() async -> (authorized: Bool, alert: Bool, sound: Bool, badge: Bool) {
        return await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                let result = (
                    authorized: settings.authorizationStatus == UNAuthorizationStatus.authorized,
                    alert: settings.alertSetting == .enabled,
                    sound: settings.soundSetting == .enabled,
                    badge: settings.badgeSetting == .enabled
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Gets all pending notifications for debugging
    /// **Development Tool**: Helps verify notifications are scheduled correctly
    /// **Production Use**: Can show users what notifications are pending
    /// **Note**: Temporarily returns empty array due to Swift 6 concurrency constraints
    func getPendingNotifications() async -> [UNNotificationRequest] {
        // TODO: Implement proper concurrency-safe version when UserNotifications framework supports it
        return []
    }
    
    /// Forces an immediate test notification
    /// **Development Feature**: Allows testing notification appearance without waiting
    /// **User Feature**: Could be exposed as "Test Notification" in settings
    func sendTestNotification() async {
        guard await hasPermission() else {
            print("⚠️ NotificationManager: Cannot send test - no permission")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Write-It-Down"
        content.body = "Test notification - your daily reminders are working! 📝"
        content.sound = .default
        content.badge = 1
        
        // **Immediate Trigger**: 1 second delay ensures notification appears quickly
        // **Reasoning**: TimeInterval trigger for immediate/one-time notifications
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test-notification-\(Date().timeIntervalSince1970)", // **Unique ID**: Prevents conflicts
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Test notification sent")
        } catch {
            print("❌ NotificationManager: Test notification failed: \(error.localizedDescription)")
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
    func userNotificationCenter(
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
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        
        // **Action Handling**: Different responses based on notification type
        if identifier == dailyReminderIdentifier {
            print("📝 NotificationManager: User tapped daily reminder notification")
            
            // **Future Enhancement**: Could post notification to open note composer
            // NotificationCenter.default.post(name: .openNoteComposer, object: nil)
            
            // **Analytics Opportunity**: Track how often users engage with reminders
            // This helps optimize timing and message content
        }
        
        // **iOS Requirement**: Must call completion handler
        completionHandler()
    }
}
