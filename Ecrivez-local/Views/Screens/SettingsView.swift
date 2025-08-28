import SwiftUI
import CoreData
import UserNotifications

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    // @StateObject private var settingsManager = UserSettingsManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showPaywall = false
    
    var body: some View {
        List {
            // Premium Status Section
            premiumStatusSection
            
            // Account & Sync Section
            accountSection
            
            // Privacy & Security Section
            privacySection
            
            // Appearance Section
            appearanceSection
            
            // Notifications Section (Temporarily Disabled)
            // notificationsSection
            
            // Categories & Organization
            organizationSection
            
            // Support Section
            supportSection
            
            // Debug Section (only in debug builds)
            #if DEBUG
            debugSection
            #endif
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Premium Status Section
    private var premiumStatusSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(premiumManager.currentTier.displayName)
                            .font(.headline)
                        
                        if premiumManager.currentTier == .premium || premiumManager.currentTier == .lifetime {
                            PremiumBadge()
                        }
                    }
                    
                    if premiumManager.currentTier == .free {
                        Text("Upgrade to unlock all features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let expiryDate = premiumManager.subscriptionExpiryDate {
                        Text("Expires: \(expiryDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if premiumManager.hasLifetimeAccess {
                        Text("Lifetime access")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                if premiumManager.currentTier == .free {
                    Button("Upgrade") {
                        showPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 4)
            
            if premiumManager.currentTier == .free {
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(feature: .unlimitedNotes, isUnlocked: false)
                    FeatureRow(feature: .cloudSync, isUnlocked: false)
                    FeatureRow(feature: .richTextFormatting, isUnlocked: false)
                }
            }
        } header: {
            Text("Subscription")
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        Section(header: Text("Account & Sync")) {
            if authViewModel.isAuthenticated {
                NavigationLink(destination: ProfileView(
                    authVM: authViewModel,
                    editedProfile: Profile(id: authViewModel.email)
                )) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text("Profile")
                    }
                }
                
                NavigationLink(destination: SyncControlView()) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Settings")
                    }
                }
            } else {
                NavigationLink(destination: AuthenticationView(authVM: authViewModel)) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Sign In")
                    }
                }
            }
        }
    }
    
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        Section(header: Text("Privacy & Security")) {
            NavigationLink(destination: PrivacySettingsView()) {
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Privacy Settings")
                    Spacer()
                    if premiumManager.currentTier == .free {
                        PremiumBadge()
                    }
                }
            }
            .premiumGate(.publicNoteSharing)
            
            // Toggle(isOn: $settingsManager.settings.enableLocationServices) {
            //     Label("Location Services", systemImage: "location")
            // }
            // .premiumGate(.locationTagging)
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Toggle(isOn: $isDarkMode) {
                Label("Dark Mode", systemImage: "moon.fill")
                    .badge(premiumManager.currentTier == .free ? Text("Premium") : nil)
            }
            .premiumGate(.darkMode)
        }
    }
    
    // MARK: - Notifications Section (Temporarily Disabled)
    /*
    /// **Enhanced Notifications UI**: Rich preference controls with smart defaults
    /// **Design Philosophy**: Progressive disclosure - show advanced options only when needed
    /// **UX Pattern**: Primary toggle first, then conditional sub-settings for enabled features
    private var notificationsSection: some View {
        Section {
            // **Primary Control**: Main toggle for daily reminders
            /// **State Management**: Bound to UserSettings for automatic persistence
            /// **Side Effects**: Enables/disables notification scheduling in real-time
            /// **Icon Choice**: Bell icon universally understood for notifications
            Toggle(isOn: Binding(
                get: { settingsManager.settings.enableDailyReminder },
                set: { newValue in
                    settingsManager.settings.enableDailyReminder = newValue
                    // **Real-time Sync**: Update notification schedule immediately when toggled
                    /// **Threading**: Uses Task to handle async notification operations on main thread
                    /// **Error Handling**: NotificationManager handles permission failures gracefully
                    Task {
                        await NotificationManager.shared.scheduleDailyReminder(
                            at: settingsManager.settings.dailyReminderTime,
                            isEnabled: newValue
                        )
                    }
                }
            )) {
                Label("Daily Writing Reminder", systemImage: "bell")
            }
            
            // **Progressive Disclosure**: Show detailed settings only when reminders are enabled
            /// **UX Principle**: Reduce cognitive load by hiding irrelevant options
            /// **Animation**: SwiftUI automatically animates this conditional appearance
            if settingsManager.settings.enableDailyReminder {
                
                // **Time Selection**: Intuitive time picker with hour/minute precision
                /// **Default Handling**: Starts with 7:00 PM (optimal reflection time)
                /// **Accessibility**: Native DatePicker provides VoiceOver support
                /// **Timezone**: Automatically handles user's local timezone
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: { settingsManager.settings.dailyReminderTime },
                        set: { newTime in
                            settingsManager.settings.dailyReminderTime = newTime
                            // **Immediate Update**: Reschedule notification with new time
                            /// **User Feedback**: Changes take effect immediately, no "save" button needed
                            Task {
                                await NotificationManager.shared.scheduleDailyReminder(
                                    at: newTime,
                                    isEnabled: settingsManager.settings.enableDailyReminder
                                )
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                
                // **Smart Notifications Toggle**: Enable contextual message selection
                /// **Feature**: Uses time of day, weekday, etc. to pick appropriate message tone
                /// **Default**: Enabled for better user experience
                /// **Fallback**: When disabled, uses simple message rotation
                Toggle(isOn: $settingsManager.settings.enableSmartNotifications) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Messages")
                            .font(.body)
                        Text("Vary message style based on time and context")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // **Permission Status Display**: Show current notification permission state
                /// **User Value**: Helps users understand why notifications might not work
                /// **Troubleshooting**: Clear indication if permissions need to be fixed
                /// **Design**: Uses @StateObject to reactively update when permissions change
                NotificationPermissionStatus()
                
                // **Test Functionality**: Allow users to verify notifications work
                /// **UX Value**: Instant feedback that notifications are configured correctly
                /// **Trust Building**: Users can confirm the feature works before depending on it
                /// **Development**: Helpful for debugging notification issues
                Button(action: {
                    Task {
                        await NotificationManager.shared.sendTestNotification()
                    }
                }) {
                    HStack {
                        Image(systemName: "paperplane")
                            .foregroundColor(.blue)
                        Text("Send Test Notification")
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
            }
            
        } header: {
            Text("Notifications")
        } footer: {
            // **Contextual Help**: Explain the value proposition of daily reminders
            /// **Content Strategy**: Focus on benefits rather than technical details
            /// **Tone**: Encouraging and supportive rather than pushy
            if settingsManager.settings.enableDailyReminder {
                Text("Daily reminders help you maintain a consistent writing practice. Messages will vary based on the time of day to keep them fresh and relevant.")
            } else {
                Text("Enable daily reminders to build a consistent writing habit with gentle, varied prompts.")
            }
        }
    }
    */
    
    // MARK: - Organization Section
    private var organizationSection: some View {
        Section {
            NavigationLink(destination: CategoryEditorListView()) {
                HStack {
                    Image(systemName: "folder")
                    Text("Categories")
                    Spacer()
                    if premiumManager.currentTier == .free {
                        Text("1/\(premiumManager.freeCategoryLimit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: MapPinCustomizationView()) {
                HStack {
                    Image(systemName: "map")
                    Text("Map Pin Customization")
                    Spacer()
                    if premiumManager.currentTier == .free {
                        PremiumBadge()
                    }
                }
            }
            .premiumGate(.mapPinCustomization)
        } header: {
            Text("Organization")
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        Section(header: Text("Settings")) {
            // Button(action: {
            //     // Reset all settings
            //     settingsManager.reset()
            // }) {
            //     Label("Reset All Settings", systemImage: "arrow.counterclockwise")
            //         .foregroundColor(.red)
            // }
        }
    }
    
    // MARK: - Debug Section
    #if DEBUG
    private var debugSection: some View {
        Section(header: Text("Debug Mode (Testing Only)")) {
            Toggle("Enable Debug Premium Mode", isOn: $premiumManager.debugModeEnabled)
            
            if premiumManager.debugModeEnabled {
                Picker("Debug Tier", selection: $premiumManager.debugTier) {
                    ForEach(PremiumTier.allCases, id: \.self) { tier in
                        Text(tier.displayName).tag(tier)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Text("Current Tier:")
                    Spacer()
                    Text(premiumManager.currentTier.displayName)
                        .foregroundColor(.secondary)
                }
                
                Text("⚠️ Debug mode is for testing only. Remember to disable before release!")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    #endif
}
