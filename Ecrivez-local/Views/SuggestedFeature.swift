//
//  SuggestedFeature.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 3/26/25.
//

import SwiftUI

@MainActor
struct SuggestFeatureView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var featureTitle: String = ""
    @State private var featureDescription: String = ""
    @State private var email: String = ""
    @State private var showConfirmation = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your Suggestion")) {
                    TextField("Feature Title", text: $featureTitle)
                    TextEditor(text: $featureDescription)
                        .frame(height: 150)
                }

                Section(header: Text("Contact (Optional)"), footer: Text("Include your email if you'd like updates about your suggestion.")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Suggestion")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task { await submitSuggestion() }
                    }
                    .disabled(featureTitle.trimmingCharacters(in: .whitespaces).isEmpty || featureDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Thanks for your suggestion!", isPresented: $showConfirmation) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    
    private func submitSuggestion() async {
        let suggestion = FeatureSuggestion(
            id: nil, // Supabase generates this automatically
            title: featureTitle,
            description: featureDescription,
            email: email.isEmpty ? nil : email
        )

        do {
//            try awaitytu69SupabaseManager.shared.submitFeatureSuggestion(suggestion)
            showConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

// Preview
struct SuggestFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestFeatureView()
    }
}
