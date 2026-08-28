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
    @EnvironmentObject private var session: AppSessionStore
    @State private var showLogoutConfirmation = false
    /// Same key `SboltApp` reads via `.preferredColorScheme` — a local,
    /// device-only preference, not routed through `SettingsViewModel`/
    /// `SettingsRepository` (unlike Push Notifications/Language, this has no
    /// backend concept to sync and needs to be readable from the app root,
    /// which doesn't have a `SettingsViewModel` instance).
    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRawValue = AppearanceMode.system.rawValue

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
            driverModeSection
            logoutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(session: session)
            viewModel.loadSettings()
        }
        .confirmationDialog("Log out of \(AppInfo.name)?",
                            isPresented: $showLogoutConfirmation,
                            titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { viewModel.logout() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Something went wrong", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.didLogout) { loggedOut in
            if loggedOut {
                session.signOut()
                viewModel.acknowledgeLogout()
            }
        }
    }

    // MARK: - Sections

    /// A genuine 3-state control (System/Light/Dark), not the previous
    /// on/off toggle that had no way to express "follow the system" — see
    /// `AppearanceMode`'s own doc comment. Reads/writes the same
    /// `@AppStorage` key `SboltApp` applies via `.preferredColorScheme`,
    /// so picking a value here changes the whole app's appearance live.
    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SettingsRow(systemImage: "moon.fill", title: "Appearance")

                Picker("Appearance", selection: appearanceModeBinding) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(.vertical, AppSpacing.xs)
            .accessibilityIdentifier("settings_appearance_picker")
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: notificationsBinding) {
                SettingsRow(systemImage: "bell.fill", title: "Push Notifications")
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
                SettingsRow(systemImage: "globe", title: "Language", value: viewModel.settings.language)
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
                SettingsRow(systemImage: "hand.raised.fill", title: "Privacy Policy")
            }

            NavigationLink {
                SettingsPlaceholderView(title: "Terms & Conditions",
                                        systemImage: "doc.text.fill",
                                        message: "Our terms & conditions will appear here.")
            } label: {
                SettingsRow(systemImage: "doc.text.fill", title: "Terms & Conditions")
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
                SettingsRow(systemImage: "star.fill", title: "Rate App")
            }

            NavigationLink {
                SettingsPlaceholderView(title: "Share App",
                                        systemImage: "square.and.arrow.up",
                                        message: "Sharing will be available in a future update.")
            } label: {
                SettingsRow(systemImage: "square.and.arrow.up", title: "Share App")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            SettingsRow(systemImage: "app.fill", title: "Application", value: AppInfo.name)
            SettingsRow(systemImage: "person.2.fill", title: "Developer", value: AppInfo.developer)
            SettingsRow(systemImage: "number", title: "Version", value: AppInfo.version)
        }
    }

    private var driverModeSection: some View {
        Section("Driver") {
            if viewModel.driverProfile != nil {
                Picker("Mode", selection: modeBinding) {
                    Text("Customer").tag(AppMode.customer)
                    Text("Driver").tag(AppMode.driver)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings_mode_picker")

                NavigationLink {
                    VehicleSettingsView(
                        viewModel: DriverModeDependencies().makeVehicleSettingsViewModel(),
                        driverProfile: viewModel.driverProfile
                    )
                } label: {
                    SettingsRow(systemImage: "scooter", title: "Vehicle & Scooter Type")
                }
                .accessibilityIdentifier("settings_vehicle_row")
            } else {
                NavigationLink {
                    SettingsPlaceholderView(
                        title: "Become a Driver",
                        systemImage: "car.fill",
                        message: "Driver sign-up isn't available yet."
                    )
                } label: {
                    SettingsRow(systemImage: "car.fill", title: "Become a Driver")
                }
                .accessibilityIdentifier("settings_become_driver_row")
            }
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

    private var appearanceModeBinding: Binding<AppearanceMode> {
        Binding(get: { AppearanceMode(rawValue: appearanceModeRawValue) ?? .system },
                set: { appearanceModeRawValue = $0.rawValue })
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(get: { viewModel.settings.isPushNotificationsEnabled },
                set: { viewModel.setPushNotifications($0) })
    }

    private var modeBinding: Binding<AppMode> {
        Binding(get: { viewModel.currentMode },
                set: { viewModel.switchMode(to: $0) })
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
        .environmentObject(AppSessionStore())
    }
}
#endif
