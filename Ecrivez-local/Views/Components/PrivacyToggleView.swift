import SwiftUI

struct PrivacyToggleView: View {
    @Binding var isPublic: Bool
    @Binding var isAnonymous: Bool
    let isAuthenticated: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Public toggle
            Toggle(isOn: $isPublic) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Make Public")
                        .font(.headline)
                    Text("Share this note with the community")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(!isAuthenticated)
            
            // Anonymous toggle
            if isPublic {
                Toggle(isOn: $isAnonymous) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Post Anonymously")
                            .font(.headline)
                        Text("Hide your identity when sharing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!isAuthenticated)
            }
            
            if !isAuthenticated {
                Text("Sign in to share notes publicly")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}