//
//  AuthMessageBanner.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Inline banner for user-facing error or success feedback. Colour and icon
/// are derived from the style so both forms present feedback identically.
struct AuthMessageBanner: View {
    enum Style {
        case error
        case success

        var color: Color {
            switch self {
            case .error: return .red
            case .success: return .green
            }
        }

        var systemImage: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }

    let message: String
    let style: Style

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: style.systemImage)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(style.color)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.color.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct AuthMessageBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            AuthMessageBanner(message: "Incorrect email or password.", style: .error)
            AuthMessageBanner(message: "Signed in successfully.", style: .success)
        }
        .padding()
    }
}
#endif
