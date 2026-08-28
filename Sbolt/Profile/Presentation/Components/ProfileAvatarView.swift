//
//  ProfileAvatarView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Circular avatar. Loads a remote image when a URL is present (ready for a
/// future backend); otherwise falls back to a solid `AppColors.accent`
/// circle with the user's initials — same treatment as
/// `DriverCard`/`RiderInfoCard`'s avatar — rather than a generic person icon.
struct ProfileAvatarView: View {
    let url: URL?
    /// Used only for the initials fallback when there's no `url` (or it
    /// fails to load). `nil` falls back further to a generic person glyph.
    var name: String?
    var size: CGFloat = 96

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        failurePlaceholder
                    case .empty:
                        loadingPlaceholder
                    @unknown default:
                        loadingPlaceholder
                    }
                }
            } else {
                // No photo at all — the case this task targets: an accent
                // circle with initials, matching DriverCard/RiderInfoCard.
                initialsPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppColors.borderHairline, lineWidth: 0.5))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var initialsPlaceholder: some View {
        if let initials {
            ZStack {
                Circle().fill(AppColors.accent)
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(AppColors.textOnAccent)
            }
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(AppColors.textMuted)
        }
    }

    private var loadingPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(AppColors.textMuted)
    }

    /// Shown when the remote image fails to load — distinct from the
    /// loading placeholder so it doesn't look like a stuck spinner forever.
    private var failurePlaceholder: some View {
        Image(systemName: "person.crop.circle.badge.exclamationmark")
            .resizable()
            .scaledToFit()
            .foregroundStyle(AppColors.textMuted)
    }

    /// Up to 2 letters from the name's first/last word — same convention
    /// `DriverCard.initials` already established.
    private var initials: String? {
        guard let name, !name.isEmpty else { return nil }
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? nil : String(letters).uppercased()
    }
}

#if DEBUG
struct ProfileAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppSpacing.lg) {
            ProfileAvatarView(url: nil, name: "Jane Driver")
            ProfileAvatarView(url: nil, name: nil)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
