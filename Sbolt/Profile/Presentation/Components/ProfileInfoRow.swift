//
//  ProfileInfoRow.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Reusable read-only row pairing an SF Symbol with a titled value, used in the
/// profile's personal-information section.
struct ProfileInfoRow: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .foregroundStyle(AppColors.accent)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppColors.textMuted)
                Text(displayValue)
                    .font(.body)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(displayValue)")
    }

    private var displayValue: String {
        value.isEmpty ? "—" : value
    }
}

#if DEBUG
struct ProfileInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ProfileInfoRow(systemImage: "person", title: "Full name", value: "Test User")
            ProfileInfoRow(systemImage: "envelope", title: "Email", value: "test@yallago.com")
        }
    }
}
#endif
