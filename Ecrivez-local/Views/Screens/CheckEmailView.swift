//
//  CheckEmailView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 12/23/24.
//
import SwiftUI

struct CheckEmailView: View {
    let email: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Check Your Email")
                .font(.title2)
                .padding(.top)

            Text("We sent a confirmation link to \(email). Please confirm your email, then come back and tap continue.")
                .multilineTextAlignment(.center)

            Button("Continue") {
                onContinue()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)

            Spacer()
        }
        .padding()
    }
}

