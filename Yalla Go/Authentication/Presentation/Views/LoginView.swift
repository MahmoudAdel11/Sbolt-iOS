//
//  LoginView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Sign-in screen. Binds to `LoginViewModel`; contains no business logic.
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @EnvironmentObject private var session: AppSessionStore
    private let dependencies: AuthenticationDependencies

    init(dependencies: AuthenticationDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeLoginViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                fields
                feedback
                AuthPrimaryButton(title: "Sign In", isLoading: viewModel.isLoading) {
                    viewModel.login()
                }
                footer
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.authenticatedUser) { user in
            guard let user else { return }
            session.signIn(user: user)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "car.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("Welcome back")
                .font(.title).bold()
            Text("Sign in to continue your journey.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var fields: some View {
        VStack(spacing: 16) {
            AuthTextField(title: "Email", systemImage: "envelope",
                          text: $viewModel.email,
                          keyboardType: .emailAddress,
                          textContentType: .emailAddress,
                          accessibilityIdentifier: "login_email_field")

            AuthTextField(title: "Password", systemImage: "lock",
                          text: $viewModel.password,
                          isSecure: true,
                          textContentType: .password,
                          accessibilityIdentifier: "login_password_field")

            NavigationLink {
                ForgotPasswordView()
            } label: {
                Text("Forgot password?")
                    .font(.footnote.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityIdentifier("login_forgot_password_link")
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if viewModel.loginSucceeded {
            AuthMessageBanner(message: "Signed in successfully.", style: .success)
                .accessibilityIdentifier("login_success_banner")
        } else if let errorMessage = viewModel.errorMessage {
            AuthMessageBanner(message: errorMessage, style: .error)
                .accessibilityIdentifier("login_error_banner")
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundStyle(.secondary)
            NavigationLink {
                RegisterView(dependencies: dependencies)
            } label: {
                Text("Sign Up").fontWeight(.semibold)
            }
            .accessibilityIdentifier("login_signup_link")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoginView(dependencies: AuthenticationDependencies())
        }
        .navigationViewStyle(.stack)
    }
}
#endif
