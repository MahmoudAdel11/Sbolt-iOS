//
//  AuthPrimaryButton.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Full-width primary action button that shows a spinner and disables itself
/// while a request is in flight.
struct AuthPrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .fontWeight(.semibold)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .foregroundStyle(.white)
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "In progress, please wait" : "")
    }
}

#if DEBUG
struct AuthPrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            AuthPrimaryButton(title: "Sign In", isLoading: false) {}
            AuthPrimaryButton(title: "Sign In", isLoading: true) {}
        }
        .padding()
    }
}
#endif
