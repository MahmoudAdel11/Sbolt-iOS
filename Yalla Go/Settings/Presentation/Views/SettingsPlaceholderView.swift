//
//  SettingsPlaceholderView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Generic placeholder used by Settings destinations that are not implemented
/// yet (Language, Privacy Policy, Terms, Rate, Share).
struct SettingsPlaceholderView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2).bold()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct SettingsPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsPlaceholderView(title: "Language",
                                    systemImage: "globe",
                                    message: "Language selection isn't available yet.")
        }
        .navigationViewStyle(.stack)
    }
}
#endif
