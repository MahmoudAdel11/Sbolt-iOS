//
//  SettingsRow.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Reusable Settings row: a tinted SF Symbol, a title, and an optional trailing
/// value. Used for navigation rows and read-only info rows.
///
/// `tint` defaults to `AppColors.accent` and every call site now relies on
/// that default — previously each row picked its own raw color (purple,
/// red, blue, gray, orange, green, teal) with no cohesion. Standardized on
/// a single consistent badge color across every row, per the confirmed
/// design (the simplest of the two offered options, and consistent with
/// every other redesigned screen already being accent-forward rather than
/// multicolor). `tint` stays overridable, not removed, in case a future
/// screen has a genuine reason to deviate.
struct SettingsRow: View {
    let systemImage: String
    let title: String
    var tint: Color = AppColors.accent
    var value: String?

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(AppColors.textOnAccent)
                .frame(width: 28, height: 28)
                .background(tint, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)

            Text(title)
                .foregroundStyle(AppColors.textPrimary)

            if let value {
                Spacer()
                Text(value)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.map { "\(title), \($0)" } ?? title)
    }
}

#if DEBUG
struct SettingsRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SettingsRow(systemImage: "globe", title: "Language", value: "English")
            SettingsRow(systemImage: "star.fill", title: "Rate App")
        }
    }
}
#endif
