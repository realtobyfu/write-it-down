import SwiftUI
import CoreLocation

struct PrivacySettingsView: View {
    @StateObject private var settingsManager = UserSettingsManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showLocationPermissionAlert = false
    @State private var showDataDeletionAlert = false
    
    var body: some View {
        Form {
            // Note Privacy Section - REMOVED: Privacy is handled per-note, not globally
            // notePrivacySection
            
            // Location Services Section
            locationSection
            
            // Data Management Section
            dataManagementSection
            
            // Social Privacy Section - REMOVED: Social features not implemented
            // socialPrivacySection
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Location Services", isPresented: $showLocationPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location services in Settings to use location features.")
        }
        .alert("Delete All Data", isPresented: $showDataDeletionAlert) {
            Button("Delete", role: .destructive) {
                // TODO: Implement data deletion functionality
                // Implementation would go here
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your notes and cannot be undone. Are you sure?")
        }
    }
    
    // REMOVED: Privacy is handled per-note in the editor, not as global defaults
    /*
    private var notePrivacySection: some View {
        Section(header: Text("Note Privacy"), footer: Text("Choose whether new notes are public or private by default")) {
            Picker("Default Note Privacy", selection: $settingsManager.settings.defaultNotePrivacy) {
                Text("Private").tag(true)
                Text("Public").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Toggle("Enable Anonymous Posting", isOn: $settingsManager.settings.enableAnonymousPosting)
        }
    }
    */
    
    private var locationSection: some View {
        Section(header: Text("Location Services"), footer: Text("Location data is used to tag notes and never shared without your permission")) {
            Toggle("Enable Location Services", isOn: $settingsManager.settings.enableLocationServices)
                .onChange(of: settingsManager.settings.enableLocationServices) { newValue in
                    if newValue {
                        checkLocationPermission()
                    }
                }
            
            if settingsManager.settings.enableLocationServices {
                HStack {
                    Text("Location Accuracy")
                    Spacer()
                    Text("Precise")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    Text("Location access: When In Use")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var dataManagementSection: some View {
        Section(header: Text("Data Management"), footer: Text("Control how long your data is retained")) {
            Picker("Data Retention", selection: $settingsManager.settings.dataRetentionDays) {
                Text("Forever").tag(0)
                Text("30 days").tag(30)
                Text("90 days").tag(90)
                Text("1 year").tag(365)
            }
            
            // TODO: Implement data export functionality
            /*
            Button(action: {
                // Export all data
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export All Data")
                }
            }
            */
            // Export is available to all users
            
            Button(action: {
                showDataDeletionAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete All Data")
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // REMOVED: Social features (comments, likes) are not implemented yet
    /*
    private var socialPrivacySection: some View {
        Section(header: Text("Social Features"), footer: Text("Control who can interact with your public notes")) {
            Toggle("Allow Comments on Public Notes", isOn: .constant(true))
            
            Toggle("Allow Likes on Public Notes", isOn: .constant(true))
            
            Toggle("Show Username on Public Notes", isOn: .constant(true))
                .disabled(!settingsManager.settings.enableAnonymousPosting)
        }
    }
    */
    
    private func checkLocationPermission() {
        let locationManager = CLLocationManager()
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            showLocationPermissionAlert = true
            settingsManager.settings.enableLocationServices = false
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
}

#Preview {
    NavigationView {
        PrivacySettingsView()
    }
}