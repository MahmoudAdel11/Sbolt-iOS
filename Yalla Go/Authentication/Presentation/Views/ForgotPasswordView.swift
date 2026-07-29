//
//  ForgotPasswordView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Placeholder for the future password-recovery flow. No logic is implemented
/// yet; it exists so navigation and layout are ready for backend integration.
struct ForgotPasswordView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text("Reset your password")
                .font(.title2).bold()
                .multilineTextAlignment(.center)

            Text("Password recovery isn't available yet. This screen is reserved for a future update.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("forgot_password_placeholder")
    }
}

#if DEBUG
struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ForgotPasswordView()
        }
        .navigationViewStyle(.stack)
    }
}
#endif
