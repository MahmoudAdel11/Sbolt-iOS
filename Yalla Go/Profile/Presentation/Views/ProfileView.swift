//
//  ProfileView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Profile screen. Binds to `ProfileViewModel`; contains no business logic.
/// Renders loading / loaded / error / empty states and hosts the edit sheet.
struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var session: AppSessionStore
    @State private var isEditing = false
    @State private var showUpdateConfirmation = false

    init(dependencies: ProfileDependencies = ProfileDependencies()) {
        _viewModel = StateObject(wrappedValue: dependencies.makeProfileViewModel())
    }

    var body: some View {
        content
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("profile_settings_link")
                }
            }
            .task {
                if viewModel.profile == nil { viewModel.loadProfile() }
            }
            .sheet(isPresented: $isEditing) {
                if let profile = viewModel.profile {
                    EditProfileView(viewModel: viewModel, profile: profile)
                }
            }
            .onChange(of: viewModel.updateSucceeded) { succeeded in
                if succeeded { flashUpdateConfirmation() }
            }
            .onChange(of: viewModel.isSessionExpired) { expired in
                if expired { session.signOut() }
            }
            .overlay(alignment: .top) {
                if showUpdateConfirmation { successBanner }
            }
    }

    // MARK: - State routing

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.profile == nil {
            loadingState
        } else if let profile = viewModel.profile {
            loadedState(profile)
        } else if let errorMessage = viewModel.errorMessage {
            errorState(errorMessage)
        } else {
            emptyState
        }
    }

    private var loadingState: some View {
        ProgressView("Loading profile…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("profile_loading")
    }

    private func loadedState(_ profile: User) -> some View {
        List {
            Section {
                headerView(profile)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }

            Section("Personal Information") {
                ProfileInfoRow(systemImage: "person", title: "Full name", value: profile.username)
                ProfileInfoRow(systemImage: "envelope", title: "Email address", value: profile.email)
                ProfileInfoRow(systemImage: "phone", title: "Phone number", value: profile.phoneNumber)
            }

            Section {
                NavigationLink {
                    FavoritePlacesListView()
                } label: {
                    Label("Saved Places", systemImage: "star.fill")
                }
                .accessibilityIdentifier("profile_saved_places_link")
                .accessibilityHint("Manage your saved places")
            }

            Section {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit Profile", systemImage: "square.and.pencil")
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("profile_edit_button")
                .accessibilityHint("Opens a form to edit your profile")
            }
        }
        .listStyle(.insetGrouped)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") { viewModel.loadProfile() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("profile_retry_button")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("profile_error_state")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No profile yet")
                .font(.title2).bold()
            Text("Complete your profile so drivers can recognise you.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Reload") { viewModel.loadProfile() }
                .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("profile_empty_state")
    }

    // MARK: - Pieces

    private func headerView(_ profile: User) -> some View {
        VStack(spacing: 12) {
            ProfileAvatarView(url: profile.profileImageURL)
            VStack(spacing: 4) {
                Text(profile.username)
                    .font(.title2).bold()
                Text(profile.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var successBanner: some View {
        Label("Profile updated", systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.green, in: Capsule())
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityIdentifier("profile_success_banner")
    }

    private func flashUpdateConfirmation() {
        withAnimation { showUpdateConfirmation = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { showUpdateConfirmation = false }
        }
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
        .navigationViewStyle(.stack)
        .environmentObject(AppSessionStore())
    }
}
#endif
