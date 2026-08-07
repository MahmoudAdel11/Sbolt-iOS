//
//  RegisterView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Registration screen. Binds to `RegisterViewModel`; contains no business logic.
struct RegisterView: View {
    @StateObject private var viewModel: RegisterViewModel
    @EnvironmentObject private var session: AppSessionStore
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AuthenticationDependencies) {
        _viewModel = StateObject(wrappedValue: dependencies.makeRegisterViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                fields
                feedback
                AuthPrimaryButton(title: "Create Account", isLoading: viewModel.isLoading) {
                    viewModel.register()
                }
                footer
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.authenticatedUser) { user in
            guard let user else { return }
            session.signIn(user: user)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Join Yalla Go")
                .font(.title).bold()
            Text("Create an account to start booking rides.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var fields: some View {
        VStack(spacing: 16) {
            AuthTextField(title: "Username", systemImage: "person",
                          text: $viewModel.username,
                          textContentType: .username,
                          accessibilityIdentifier: "register_username_field")

            AuthTextField(title: "Email", systemImage: "envelope",
                          text: $viewModel.email,
                          keyboardType: .emailAddress,
                          textContentType: .emailAddress,
                          accessibilityIdentifier: "register_email_field")

            AuthTextField(title: "Phone number", systemImage: "phone",
                          text: $viewModel.phoneNumber,
                          keyboardType: .phonePad,
                          textContentType: .telephoneNumber,
                          accessibilityIdentifier: "register_phone_field")

            AuthTextField(title: "Password", systemImage: "lock",
                          text: $viewModel.password,
                          isSecure: true,
                          textContentType: .newPassword,
                          accessibilityIdentifier: "register_password_field")

            AuthTextField(title: "Confirm password", systemImage: "lock.rotation",
                          text: $viewModel.confirmPassword,
                          isSecure: true,
                          textContentType: .newPassword,
                          accessibilityIdentifier: "register_confirm_password_field")
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if viewModel.registrationSucceeded {
            AuthMessageBanner(message: "Account created successfully.", style: .success)
                .accessibilityIdentifier("register_success_banner")
        } else if let errorMessage = viewModel.errorMessage {
            AuthMessageBanner(message: errorMessage, style: .error)
                .accessibilityIdentifier("register_error_banner")
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .foregroundStyle(.secondary)
            Button { dismiss() } label: {
                Text("Sign In").fontWeight(.semibold)
            }
            .accessibilityIdentifier("register_signin_link")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegisterView(dependencies: AuthenticationDependencies())
        }
        .navigationViewStyle(.stack)
    }
}
#endif
