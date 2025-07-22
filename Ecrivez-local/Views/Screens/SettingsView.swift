import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var settingsManager = UserSettingsManager.shared
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
            
            // Editor Preferences Section
            editorSection
            
            // Privacy & Security Section
            privacySection
            
            // Appearance Section
            appearanceSection
            
            // Notifications Section
            notificationsSection
            
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
    
    // MARK: - Editor Section
    private var editorSection: some View {
        Section(header: Text("Editor Preferences")) {
            NavigationLink(destination: EditorPreferencesView()) {
                HStack {
                    Image(systemName: "textformat")
                    Text("Text & Formatting")
                    Spacer()
                    if premiumManager.currentTier == .free {
                        PremiumBadge()
                    }
                }
            }
            .premiumGate(.richTextFormatting)
            
            Picker("Default Note Type", selection: $settingsManager.settings.defaultNoteType) {
                Text("Note").tag("note")
                Text("List").tag("list")
                Text("Task").tag("task")
            }
            
            HStack {
                Label("Default Color", systemImage: "paintpalette")
                Spacer()
                Circle()
                    .fill(Color(settingsManager.settings.defaultNoteColor))
                    .frame(width: 24, height: 24)
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
            
            Toggle(isOn: $settingsManager.settings.enableLocationServices) {
                Label("Location Services", systemImage: "location")
            }
            .premiumGate(.locationTagging)
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Toggle(isOn: $isDarkMode) {
                Label("Dark Mode", systemImage: "moon.fill")
                    .badge(premiumManager.currentTier == .free ? Text("PRO") : nil)
            }
            .premiumGate(.darkMode)
            
            Picker("Theme", selection: $settingsManager.settings.appTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .premiumGate(.customThemes)
            
            Picker("Note List Density", selection: $settingsManager.settings.noteListDensity) {
                Text("Compact").tag("compact")
                Text("Standard").tag("standard")
                Text("Comfortable").tag("comfortable")
            }
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section(header: Text("Notifications")) {
            Toggle(isOn: $settingsManager.settings.enableSyncNotifications) {
                Label("Sync Notifications", systemImage: "arrow.triangle.2.circlepath")
            }
            
            Toggle(isOn: $settingsManager.settings.enableDailyReminder) {
                Label("Daily Writing Reminder", systemImage: "bell")
            }
            
            if settingsManager.settings.enableDailyReminder {
                DatePicker("Reminder Time",
                          selection: $settingsManager.settings.dailyReminderTime,
                          displayedComponents: .hourAndMinute)
            }
            
            Toggle(isOn: $settingsManager.settings.enableSocialNotifications) {
                Label("Social Interactions", systemImage: "heart")
            }
            .premiumGate(.socialFeatures)
        }
    }
    
    // MARK: - Organization Section
    private var organizationSection: some View {
        Section(header: Text("Organization")) {
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
            
            NavigationLink(destination: Text("Map Pin Customization Coming Soon")
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            ) {
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
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        Section(header: Text("Support & Feedback")) {
            NavigationLink(destination: SuggestFeatureView()) {
                Label("Suggest a Feature", systemImage: "lightbulb")
            }
            
            NavigationLink(destination: DonationView()) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Support the Developer")
                    Spacer()
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Button(action: {
                // Reset all settings
                settingsManager.reset()
            }) {
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    .foregroundColor(.red)
            }
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
