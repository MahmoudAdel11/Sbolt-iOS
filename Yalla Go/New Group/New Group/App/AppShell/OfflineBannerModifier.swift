//
//  OfflineBannerModifier.swift
//  Yalla Go
//

import SwiftUI

/// Generic, app-wide "no connection" indicator. Applied once at the root
/// (`RootView`) rather than per-feature — every screen gets it for free.
private struct OfflineBannerModifier: ViewModifier {
    @EnvironmentObject private var connectivity: ConnectivityStore

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if !connectivity.isConnected {
                Label("No Internet Connection", systemImage: "wifi.slash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityIdentifier("offline_banner")
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: connectivity.isConnected)
    }
}

extension View {
    /// Shows a banner at the top of the screen while the device has no
    /// connection, and hides it automatically once connectivity returns.
    func offlineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}
