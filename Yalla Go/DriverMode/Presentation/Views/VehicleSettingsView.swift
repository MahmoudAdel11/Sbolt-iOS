//
//  VehicleSettingsView.swift
//  Yalla Go
//

import SwiftUI

/// Lets a driver set/edit their vehicle details and scooter type — the
/// screen a driver who registered before `scooter_type` existed (or who
/// skipped it) uses to set it later. Matches `EditProfileView`'s form
/// conventions (styling, save-button placement, loading/error handling)
/// rather than inventing a new visual style.
struct VehicleSettingsView: View {
    @ObservedObject private var viewModel: VehicleSettingsViewModel
    @EnvironmentObject private var session: AppSessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var vehicleType: String
    @State private var vehicleColor: String
    @State private var licensePlate: String
    @State private var scooterType: RideType?

    init(viewModel: VehicleSettingsViewModel, driverProfile: DriverProfile?) {
        self.viewModel = viewModel
        _vehicleType = State(initialValue: driverProfile?.vehicleType ?? "")
        _vehicleColor = State(initialValue: driverProfile?.vehicleColor ?? "")
        _licensePlate = State(initialValue: driverProfile?.licensePlate ?? "")
        _scooterType = State(initialValue: driverProfile?.scooterType)
    }

    var body: some View {
        Form {
            Section {
                TextField("Vehicle type", text: $vehicleType)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("vehicle_type_field")

                TextField("Vehicle color", text: $vehicleColor)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("vehicle_color_field")

                TextField("License plate", text: $licensePlate)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("license_plate_field")
            } header: {
                Text("Vehicle Details")
            } footer: {
                Text("Leave a field blank to leave it unchanged.")
            }

            Section("Scooter Type") {
                // "Not Set" only matters as a starting placeholder — re-selecting
                // it sends `nil`, which (like every other field here) means
                // "leave unchanged," not "clear it." There's no way to clear an
                // already-set scooter type from this screen.
                Picker("Scooter type", selection: $scooterType) {
                    Text("Not Set").tag(RideType?.none)
                    ForEach(RideType.allCases) { type in
                        Text(type.description).tag(RideType?.some(type))
                    }
                }
                .accessibilityIdentifier("vehicle_scooter_type_picker")
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("vehicle_settings_error_message")
                }
            }
        }
        .navigationTitle("Vehicle & Scooter Type")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Save") { save() }
                        .accessibilityIdentifier("vehicle_settings_save_button")
                }
            }
        }
        .onChange(of: viewModel.updatedUser) { user in
            guard let user else { return }
            session.updateCurrentUser(user)
        }
        .onChange(of: viewModel.updateSucceeded) { succeeded in
            if succeeded { dismiss() }
        }
        .onChange(of: viewModel.isSessionExpired) { expired in
            if expired { session.signOut() }
        }
    }

    private func save() {
        viewModel.updateVehicle(
            vehicleType: nonEmpty(vehicleType),
            vehicleColor: nonEmpty(vehicleColor),
            licensePlate: nonEmpty(licensePlate),
            scooterType: scooterType
        )
    }

    /// Trims and converts blank input to `nil` — an empty field means "don't
    /// send this field" (leave unchanged), matching the backend's optional
    /// partial-update semantics, not "clear this field" (which the backend
    /// doesn't support here — `min_length: 1` on the free-text fields).
    private func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#if DEBUG
struct VehicleSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VehicleSettingsView(
                viewModel: DriverModeDependencies().makeVehicleSettingsViewModel(),
                driverProfile: DriverProfile(isOnline: false)
            )
        }
        .navigationViewStyle(.stack)
        .environmentObject(AppSessionStore())
    }
}
#endif
