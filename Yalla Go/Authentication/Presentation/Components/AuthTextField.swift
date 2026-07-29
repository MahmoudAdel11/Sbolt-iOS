//
//  AuthTextField.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Reusable labelled input row used across the authentication forms.
/// Handles plain/secure entry, keyboard configuration, and accessibility.
struct AuthTextField: View {
    let title: String
    let systemImage: String
    @Binding var text: String

    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never
    var accessibilityIdentifier: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)
                .accessibilityHidden(true)

            input
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .font(.body)
                .accessibilityLabel(title)
                .accessibilityIdentifier(accessibilityIdentifier ?? title)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var input: some View {
        if isSecure {
            SecureField(title, text: $text)
        } else {
            TextField(title, text: $text)
        }
    }
}

#if DEBUG
struct AuthTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            AuthTextField(title: "Email", systemImage: "envelope",
                          text: .constant("rider@yallago.com"),
                          keyboardType: .emailAddress)
            AuthTextField(title: "Password", systemImage: "lock",
                          text: .constant("secret"), isSecure: true)
        }
        .padding()
    }
}
#endif
