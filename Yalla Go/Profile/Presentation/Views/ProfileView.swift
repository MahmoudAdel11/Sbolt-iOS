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

    /// A `ScrollView` of custom cards, not a native `List` — matches the
    /// card style (`AppColors.backgroundPrimary` + `AppRadius.card`) every
    /// other redesigned screen already uses, which a native `List` Section
    /// can't produce (its corner radius/background aren't customizable to
    /// these tokens).
    private func loadedState(_ profile: User) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                headerView(profile)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    sectionLabel("Personal Information")
                    VStack(spacing: AppSpacing.md) {
                        ProfileInfoRow(systemImage: "person", title: "Full name", value: profile.username)
                        Divider().background(AppColors.borderHairline)
                        ProfileInfoRow(systemImage: "envelope", title: "Email address", value: profile.email)
                        Divider().background(AppColors.borderHairline)
                        ProfileInfoRow(systemImage: "phone", title: "Phone number", value: profile.phoneNumber)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.backgroundPrimary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                }

                NavigationLink {
                    FavoritePlacesListView()
                } label: {
                    badgedRow(systemImage: "star.fill", title: "Saved Places")
                }
                .accessibilityIdentifier("profile_saved_places_link")
                .accessibilityHint("Manage your saved places")

                // Kept as a button-triggered sheet, same as before — only the
                // visual treatment changed (icon badge + chevron, matching
                // every other row on this screen), not the interaction
                // (still opens EditProfileView as a sheet, not a push).
                Button {
                    isEditing = true
                } label: {
                    badgedRow(systemImage: "square.and.pencil", title: "Edit Profile")
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("profile_edit_button")
                .accessibilityHint("Opens a form to edit your profile")
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.backgroundSubtle)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColors.textMuted)
            .padding(.horizontal, AppSpacing.xs)
    }

    /// Row style shared by Saved Places / Edit Profile: an accent icon in a
    /// small tinted badge, a title, and a trailing chevron — matching the
    /// row language established in Settings.
    private func badgedRow(systemImage: String, title: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColors.accent)
                    .frame(width: 32, height: 32)
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textOnAccent)
            }
            Text(title)
                .font(.body)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textDisabled)
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundPrimary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
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
        VStack(spacing: AppSpacing.sm) {
            ProfileAvatarView(url: profile.profileImageURL, name: profile.username)
            VStack(spacing: 4) {
                Text(profile.username)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(profile.email)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
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
