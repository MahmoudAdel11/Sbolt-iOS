//
//  LocationSearchActivationView.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/01/2025.
//

import SwiftUI

/// The "Where to go?" search bar on Home's idle state — tapping it starts
/// the destination search flow (see `HomeView`'s `onTapGesture`).
struct LocationSearchActivationView: View {
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.accent)

            Text("Where to go?")
                .foregroundStyle(AppColors.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .padding(.horizontal, AppSpacing.lg)
    }
}

struct LocationSearchActivationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchActivationView()
    }
}
