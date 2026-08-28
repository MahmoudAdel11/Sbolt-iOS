//
//  DesignSystemPreview.swift
//  Yalla Go
//

import SwiftUI

/// Not used anywhere in the app — exists purely so every `AppColors` token
/// can be visually sanity-checked in both appearances via Xcode's canvas
/// (or the light/dark preview trait below) without needing a real screen
/// built on top of them yet.
#if DEBUG
private struct DesignSystemPreviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                swatchRow("backgroundPrimary", AppColors.backgroundPrimary)
                swatchRow("backgroundSecondary", AppColors.backgroundSecondary)
                swatchRow("backgroundSubtle", AppColors.backgroundSubtle)
                swatchRow("borderHairline", AppColors.borderHairline)
                swatchRow("textPrimary", AppColors.textPrimary)
                swatchRow("textSecondary", AppColors.textSecondary)
                swatchRow("textMuted", AppColors.textMuted)
                swatchRow("textDisabled", AppColors.textDisabled)
                swatchRow("accent", AppColors.accent)
                swatchRow("accentTextDark", AppColors.accentTextDark)
                swatchRow("accentTextSecondary", AppColors.accentTextSecondary)
                swatchRow("accentTint", AppColors.accentTint)
                swatchRow("textOnAccent", AppColors.textOnAccent)
                swatchRow("danger", AppColors.danger)
                swatchRow("successBackground", AppColors.successBackground)
                swatchRow("successText", AppColors.successText)
                swatchRow("warningBackground", AppColors.warningBackground)
                swatchRow("warningText", AppColors.warningText)
                swatchRow("ratingGold", AppColors.ratingGold)
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.backgroundPrimary)
    }

    private func swatchRow(_ name: String, _ color: Color) -> some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.card / 2)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card / 2)
                        .stroke(AppColors.borderHairline, lineWidth: 1)
                )
            Text(name)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
    }
}

struct DesignSystemPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DesignSystemPreviewView()
                .previewDisplayName("Light")
                .preferredColorScheme(.light)
            DesignSystemPreviewView()
                .previewDisplayName("Dark")
                .preferredColorScheme(.dark)
        }
    }
}
#endif
