//
//  EditProfileView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Edit form presented as a sheet. Holds local field state, submits a
/// `ProfileUpdate` intent to the shared view model, and reflects the view
/// model's loading / error / success state.
struct EditProfileView: View {
    @ObservedObject private var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username: String
    @State private var email: String
    @State private var phoneNumber: String

    private let currentImageURL: URL?

    init(viewModel: ProfileViewModel, profile: User) {
        self.viewModel = viewModel
        self.currentImageURL = profile.profileImageURL
        _username = State(initialValue: profile.username)
        _email = State(initialValue: profile.email)
        _phoneNumber = State(initialValue: profile.phoneNumber)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("edit_username_field")

                    TextField("Email address", text: $email)
                        .disabled(true)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("edit_email_field")

                    TextField("Phone number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .accessibilityIdentifier("edit_phone_field")
                } header: {
                    Text("Personal Information")
                } footer: {
                    Text("Email can't be changed yet.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("edit_error_message")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(viewModel.isLoading)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .disabled(username.isEmpty)
                            .accessibilityIdentifier("edit_save_button")
                    }
                }
            }
            .onChange(of: viewModel.updateSucceeded) { succeeded in
                if succeeded { dismiss() }
            }
        }
    }

    private func save() {
        let update = ProfileUpdate(username: username,
                                   phoneNumber: phoneNumber,
                                   profileImageURL: currentImageURL)
        viewModel.updateProfile(update)
    }
}

#if DEBUG
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(viewModel: ProfileDependencies().makeProfileViewModel(),
                        profile: MockProfileRepository.makeSampleProfile())
    }
}
#endif
