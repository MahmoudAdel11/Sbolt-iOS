//
//  SettingsView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Native iOS Settings screen. Binds to `SettingsViewModel`; contains no
/// business logic. Toggles, navigation, about info, and logout all route
/// through the view model.
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showLogoutConfirmation = false

    init(dependencies: SettingsDependencies = SettingsDependencies()) {
        _viewModel = StateObject(wrappedValue: dependencies.makeSettingsViewModel())
    }

    var body: some View {
        List {
            appearanceSection
            notificationsSection
            languageSection
            legalSection
            supportSection
            aboutSection
            logoutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.loadSettings() }
        .confirmationDialog("Log out of \(AppInfo.name)?",
                            isPresented: $showLogoutConfirmation,
                            titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { viewModel.logout() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Signed Out", isPresented: logoutAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've been signed out (mock). Navigation will be added later.")
        }
        .alert("Something went wrong", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle(isOn: darkModeBinding) {
                SettingsRow(systemImage: "moon.fill", title: "Dark Mode", tint: .indigo)
            }
            .accessibilityIdentifier("settings_dark_mode_toggle")
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: notificationsBinding) {
                SettingsRow(systemImage: "bell.fill", title: "Push Notifications", tint: .red)
            }
            .accessibilityIdentifier("settings_notifications_toggle")
        }
    }

    private var languageSection: some View {
        Section("Language") {
            NavigationLink {
                SettingsPlaceholderView(title: "Language",
                                        systemImage: "globe",
                                        message: "Language selection isn't available yet.")
            } label: {
                SettingsRow(systemImage: "globe", title: "Language",
                            tint: .blue, value: viewModel.settings.language)
            }
            .accessibilityIdentifier("settings_language_row")
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            NavigationLink {
                SettingsPlaceholderView(title: "Privacy Policy",
                                        systemImage: "hand.raised.fill",
                                        message: "Our privacy policy will appear here.")
            } label: {
                SettingsRow(systemImage: "hand.raised.fill", title: "Privacy Policy", tint: .gray)
            }

            NavigationLink {
                SettingsPlaceholderView(title: "Terms & Conditions",
                                        systemImage: "doc.text.fill",
                                        message: "Our terms & conditions will appear here.")
            } label: {
                SettingsRow(systemImage: "doc.text.fill", title: "Terms & Conditions", tint: .gray)
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink {
                SettingsPlaceholderView(title: "Rate App",
                                        systemImage: "star.fill",
                                        message: "App Store rating will be available in a future update.")
            } label: {
                SettingsRow(systemImage: "star.fill", title: "Rate App", tint: .orange)
            }

            NavigationLink {
                SettingsPlaceholderView(title: "Share App",
                                        systemImage: "square.and.arrow.up",
                                        message: "Sharing will be available in a future update.")
            } label: {
                SettingsRow(systemImage: "square.and.arrow.up", title: "Share App", tint: .green)
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            SettingsRow(systemImage: "app.fill", title: "Application", tint: .teal, value: AppInfo.name)
            SettingsRow(systemImage: "person.2.fill", title: "Developer", tint: .teal, value: AppInfo.developer)
            SettingsRow(systemImage: "number", title: "Version", tint: .teal, value: AppInfo.version)
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Log Out").fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier("settings_logout_button")
        }
    }

    // MARK: - Bindings

    private var darkModeBinding: Binding<Bool> {
        Binding(get: { viewModel.settings.isDarkModeEnabled },
                set: { viewModel.setDarkMode($0) })
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(get: { viewModel.settings.isPushNotificationsEnabled },
                set: { viewModel.setPushNotifications($0) })
    }

    private var logoutAlertBinding: Binding<Bool> {
        Binding(get: { viewModel.didLogout },
                set: { if !$0 { viewModel.acknowledgeLogout() } })
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } })
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
        .navigationViewStyle(.stack)
    }
}
#endif
