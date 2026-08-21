//
//  InlineBanner.swift
//  Yalla Go
//

import SwiftUI

/// Inline feedback banner for driver-mode screens. `.neutral` covers
/// non-alarming information (e.g. a lost accept race) that shouldn't read as
/// an error; `.error` covers actual failures.
struct InlineBanner: View {
    enum Tone {
        case neutral
        case error

        var color: Color {
            switch self {
            case .neutral: return .blue
            case .error: return .red
            }
        }

        var systemImage: String {
            switch self {
            case .neutral: return "info.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }

    let message: String
    let tone: Tone

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: tone.systemImage)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(tone.color)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
