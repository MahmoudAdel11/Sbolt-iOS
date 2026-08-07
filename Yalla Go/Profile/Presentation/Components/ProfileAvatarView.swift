//
//  ProfileAvatarView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Circular avatar. Loads a remote image when a URL is present (ready for a
/// future backend) and falls back to an SF Symbol placeholder otherwise.
struct ProfileAvatarView: View {
    let url: URL?
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
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
    }

    /// Shown when the remote image fails to load — distinct from the
    /// loading placeholder so it doesn't look like a stuck spinner forever.
    private var failurePlaceholder: some View {
        Image(systemName: "person.crop.circle.badge.exclamationmark")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
    }
}

#if DEBUG
struct ProfileAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileAvatarView(url: nil)
            .padding()
    }
}
#endif
