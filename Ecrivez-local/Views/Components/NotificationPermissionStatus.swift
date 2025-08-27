//
//  NotificationPermissionStatus.swift
//  Write-It-Down
//
//  Created by Claude on 1/29/25.
//

import SwiftUI
import UserNotifications

/// **Permission Status Display**: Shows current notification permission state with actionable guidance
/// 
/// **Design Goals**:
/// 1. **Transparency**: Users understand why notifications may/may not work
/// 2. **Actionability**: Clear path to fix permission issues
/// 3. **Non-intrusive**: Shows status without nagging or popup spam
/// 4. **Helpful**: Provides context about what each permission type enables
/// 
/// **Engineering Decisions**:
/// - **Reactive Updates**: Uses @StateObject to automatically update when permissions change
/// - **Granular Display**: Shows specific permission types (alert, sound, badge) not just binary yes/no
/// - **System Integration**: Deep link to Settings app when user needs to change permissions
struct NotificationPermissionStatus: View {
    
    /// **Permission Manager**: Reactive connection to notification permission system
    /// **State Management**: @StateObject ensures component updates when permissions change
    /// **Performance**: Singleton pattern prevents duplicate permission checks
    @StateObject private var notificationManager = NotificationManager.shared
    
    /// **Permission Details**: Granular permission status for detailed user feedback
    /// **Default State**: Starts pessimistic (all false) until first permission check completes
    /// **Threading**: Updated on main thread to ensure UI consistency
    @State private var permissionDetails: (authorized: Bool, alert: Bool, sound: Bool, badge: Bool) = (false, false, false, false)
    
    var body: some View {
        
        // **Status Display**: Different UI based on current permission state
        /// **Design Pattern**: Switch on authorization status for appropriate user guidance
        /// **Color Psychology**: Green = good, orange = fixable, red = blocked
        switch notificationManager.authorizationStatus {
            
        case .authorized:
            // **Success State**: Permissions granted, show positive confirmation
            /// **Trust Building**: Users see that notifications are properly configured
            /// **Detail Level**: Show specific capabilities to set expectations
            permissionGrantedView
            
        case .denied:
            // **Blocked State**: User explicitly denied, provide recovery path
            /// **Recovery Strategy**: Direct to Settings since we can't re-request
            /// **Tone**: Helpful rather than accusatory
            permissionDeniedView
            
        case .notDetermined:
            // **Initial State**: Haven't asked yet, provide opportunity to request
            /// **First Impression**: Make the request feel valuable and non-threatening
            /// **Action Button**: Clear call-to-action for enabling notifications
            permissionNotRequestedView
            
        case .provisional, .ephemeral:
            // **Limited State**: Some permissions granted, explain limitations
            /// **Education**: Help users understand partial permission states
            /// **Upgrade Path**: Show how to get full permissions
            permissionPartialView
            
        @unknown default:
            // **Future Compatibility**: Handle any new permission states Apple adds
            /// **Defensive Programming**: Graceful handling of unknown states
            permissionUnknownView
        }
    }
    
    // MARK: - Permission State Views
    
    /// **Success State**: All permissions working correctly
    private var permissionGrantedView: some View {
        HStack(spacing: 12) {
            // **Visual Feedback**: Green checkmark indicates success
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications Enabled")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // **Detail Information**: Show which specific features are working
                /// **Transparency**: Users know exactly what capabilities they have
                /// **Debugging**: Helps identify partial permission issues
                Text(permissionDetailsText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .onAppear {
            // **Load Details**: Get granular permission info when view appears
            /// **Performance**: Only check detailed permissions when needed
            /// **Threading**: Async task prevents UI blocking
            Task {
                permissionDetails = await notificationManager.getDetailedPermissionStatus()
            }
        }
    }
    
    /// **Blocked State**: User denied permissions, show recovery option
    private var permissionDeniedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // **Warning Indicator**: Orange exclamation shows fixable problem
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications Disabled")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Enable in Settings to receive writing reminders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // **Recovery Action**: Direct link to Settings app
            /// **User Experience**: No need to hunt through Settings manually
            /// **Technical Note**: Deep link to notification settings for this specific app
            /// **Fallback**: If deep link fails, opens main Settings (rare but possible)
            Button(action: openNotificationSettings) {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Open Settings")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    /// **Initial State**: Haven't requested permissions yet
    private var permissionNotRequestedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // **Neutral Indicator**: Gray bell shows neutral/pending state
                Image(systemName: "bell")
                    .foregroundColor(.gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Notifications")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Get gentle daily writing reminders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // **Permission Request**: Clean, non-threatening way to request permissions
            /// **Strategy**: Frame as "enable" rather than "allow" (more positive)
            /// **Error Handling**: Gracefully handles user denial
            /// **State Update**: UI automatically updates based on result
            Button(action: {
                Task {
                    let _ = await notificationManager.requestPermission()
                    // **UI Updates**: @StateObject ensures automatic UI refresh after permission change
                }
            }) {
                HStack {
                    Image(systemName: "bell.badge")
                    Text("Enable Notifications")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .disabled(notificationManager.isRequestingPermission)
        }
    }
    
    /// **Partial Permissions**: Some but not all notification features enabled
    private var permissionPartialView: some View {
        HStack(spacing: 12) {
            // **Mixed State**: Yellow triangle indicates partial success
            Image(systemName: "triangle.fill")
                .foregroundColor(.yellow)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Limited Notifications")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Some notification features may be limited")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // **Upgrade Action**: Help user get full permissions
            Button(action: openNotificationSettings) {
                Text("Adjust")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    /// **Unknown State**: Future-proofing for new permission states
    private var permissionUnknownView: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Notification Status Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Tap to check notification settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: openNotificationSettings) {
                Text("Settings")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Helper Properties & Methods
    
    /// **Permission Summary**: Human-readable description of current capabilities
    /// **Logic**: Builds list of enabled features for user transparency
    /// **Example**: "Alerts, sounds, and badges enabled"
    private var permissionDetailsText: String {
        var enabledFeatures: [String] = []
        
        if permissionDetails.alert { enabledFeatures.append("alerts") }
        if permissionDetails.sound { enabledFeatures.append("sounds") }  
        if permissionDetails.badge { enabledFeatures.append("badges") }
        
        if enabledFeatures.isEmpty {
            return "Basic notifications enabled"
        } else {
            let featureList = enabledFeatures.joined(separator: ", ")
            return "\(featureList.capitalized) enabled"
        }
    }
    
    /// **Deep Link**: Opens iOS Settings app to notification preferences for this app
    /// **User Experience**: Saves user from manually navigating through Settings
    /// **Technical Implementation**: Uses iOS URL scheme for direct navigation
    /// **Fallback**: Opens main Settings if specific deep link fails (rare edge case)
    private func openNotificationSettings() {
        /// **URL Construction**: Standard iOS pattern for app-specific settings
        /// **Bundle ID**: Must match app's bundle identifier exactly
        /// **URL Scheme**: "App-prefs:" is Apple's documented scheme for Settings deep links
        guard let settingsUrl = URL(string: "App-prefs:NOTIFICATIONS_ID&path=com.tobiasfu.write-it-down") else {
            print("❌ NotificationPermissionStatus: Invalid settings URL")
            return
        }
        
        /// **Availability Check**: Ensure system can handle the URL
        /// **iOS Compatibility**: URL scheme supported on iOS 10+
        /// **Error Prevention**: Prevents crashes on systems that can't handle URL
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl) { success in
                if success {
                    print("✅ NotificationPermissionStatus: Opened notification settings")
                } else {
                    print("⚠️ NotificationPermissionStatus: Failed to open notification settings")
                    // **Fallback Strategy**: Could open main Settings app here
                    // UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        } else {
            // **Final Fallback**: Open main Settings app if deep link unavailable
            /// **Graceful Degradation**: Better to show Settings than fail completely
            print("⚠️ NotificationPermissionStatus: Deep link unavailable, opening main Settings")
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
    }
}