//
//  Yalla_GoApp.swift
//  Yalla Go
//
//  Created by Mahmoud on 11/09/2024.
//

import SwiftUI

@main
struct Yalla_GoApp: App {
    @StateObject private var locationViewModel = LocationSearchViewModel()
    @StateObject private var session = AppSessionStore()
    @StateObject private var connectivity = ConnectivityStore()
    /// Same `@AppStorage` key the Settings screen's picker writes to — both
    /// observe the same persisted value, so switching it there updates the
    /// whole app live, with no other wiring needed.
    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRawValue = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationViewModel)
                .environmentObject(session)
                .environmentObject(connectivity)
                .task { await session.bootstrap() }
                .preferredColorScheme(
                    (AppearanceMode(rawValue: appearanceModeRawValue) ?? .system).colorScheme
                )
        }
    }
}
