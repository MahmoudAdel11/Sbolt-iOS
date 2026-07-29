//
//  AuthenticationRootView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Entry point and navigation host for the authentication flow. Owns the shared
/// dependencies so every screen resolves its view model from the same mock
/// repository. Not yet wired into the app; use directly or via previews.
struct AuthenticationRootView: View {
    // Held in @State so the dependency graph (and its repository) survives redraws.
    @State private var dependencies = AuthenticationDependencies()

    var body: some View {
        NavigationView {
            LoginView(dependencies: dependencies)
        }
        .navigationViewStyle(.stack)
    }
}

#if DEBUG
struct AuthenticationRootView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationRootView()
    }
}
#endif
