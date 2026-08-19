//
//  DriverModeTabView.swift
//  Yalla Go
//

import SwiftUI

/// Placeholder root shown while `AppSessionStore.currentMode == .driver`.
/// Proves the mode-switch plumbing (RootView branching, Settings' mode
/// control, AppSessionStore's gating) works end-to-end. Phase 2 replaces
/// this single screen with the real driver tab set (available rides,
/// online/offline status, driver-side trip history).
struct DriverModeTabView: View {
    @EnvironmentObject private var session: AppSessionStore

    var body: some View {
        TabView {
            NavigationView {
                comingSoon
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Driving", systemImage: "car.fill")
            }
        }
    }

    private var comingSoon: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Driver Mode")
                .font(.title2).bold()
            Text("Driver Mode — Coming Soon")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Switch Back to Customer Mode") {
                session.switchMode(to: .customer)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("driver_mode_switch_back_button")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Driver Mode")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("driver_mode_placeholder")
    }
}

#if DEBUG
struct DriverModeTabView_Previews: PreviewProvider {
    static var previews: some View {
        DriverModeTabView()
            .environmentObject(AppSessionStore())
    }
}
#endif
