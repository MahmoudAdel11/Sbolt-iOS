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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationViewModel)
                .environmentObject(session)
                .environmentObject(connectivity)
                .task { await session.bootstrap() }
        }
    }
}
