//
//  RootView.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import SwiftUI

/// Top-level container. Shows the authenticated app shell or the authentication
/// flow based on the centralised `AppSessionStore`. Today the session defaults
/// to authenticated (mock); wiring the real login flow later means only
/// flipping `AppSessionStore.isAuthenticated`.
struct RootView: View {
    @EnvironmentObject private var session: AppSessionStore

    var body: some View {
        if session.isAuthenticated {
            MainTabView()
        } else {
            AuthenticationRootView()
        }
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppSessionStore())
            .environmentObject(LocationSearchViewModel())
    }
}
#endif
