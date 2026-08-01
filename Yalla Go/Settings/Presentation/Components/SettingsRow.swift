//
//  SettingsRow.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Reusable Settings row: a tinted SF Symbol, a title, and an optional trailing
/// value. Used for navigation rows and read-only info rows.
struct SettingsRow: View {
    let systemImage: String
    let title: String
    var tint: Color = .accentColor
    var value: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)

            Text(title)

            if let value {
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
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
            SettingsRow(systemImage: "globe", title: "Language", tint: .blue, value: "English")
            SettingsRow(systemImage: "star.fill", title: "Rate App", tint: .orange)
        }
    }
}
#endif
