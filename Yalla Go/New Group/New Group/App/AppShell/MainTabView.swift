//
//  MainTabView.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import SwiftUI

/// The authenticated application shell: a native tab bar wiring the existing
/// Home, Trip History, and Profile features together. Each tab that needs a
/// title bar / push navigation gets its own `NavigationView`; Home stays
/// full-screen (it owns its own map overlays), so it is not wrapped.
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            NavigationView {
                TripHistoryView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Trips", systemImage: "clock.fill")
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
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(LocationSearchViewModel())
    }
}
#endif
