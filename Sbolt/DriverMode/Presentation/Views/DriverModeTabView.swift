//
//  DriverModeTabView.swift
//  Yalla Go
//

import SwiftUI

/// Root shown while `AppSessionStore.currentMode == .driver`. Mirrors
/// `MainTabView`'s conventions: each tab needing push nav/title bar gets its
/// own `NavigationView`. "History" reuses the exact same `TripHistoryView`/
/// `TripHistoryViewModel` the rider side uses — only `TripHistoryDependencies`'
/// `view: .driver` differs, so `GET /rides/history?as=driver` is fetched
/// instead — no parallel driver history screen needed. "Profile" reuses
/// `ProfileView` as-is — it's the only path to Settings, and Settings is
/// where the mode switch back to Customer lives, so driver mode needs it too.
struct DriverModeTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                DriverHomeView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Drive", systemImage: "car.fill")
            }

            NavigationView {
                TripHistoryView(dependencies: TripHistoryDependencies(view: .driver))
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }

            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
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
