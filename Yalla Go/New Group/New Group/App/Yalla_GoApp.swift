//
//  Yalla_GoApp.swift
//  Yalla Go
//
//  Created by Mahmoud on 11/09/2024.
//

import SwiftUI

@main
struct Yalla_GoApp: App {
    @StateObject var  locationViewModel = LocationSearchViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(locationViewModel)
        }
    }
}
