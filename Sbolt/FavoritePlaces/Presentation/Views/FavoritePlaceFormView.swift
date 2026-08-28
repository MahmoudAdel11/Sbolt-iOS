//
//  FavoritePlaceFormView.swift
//  Yalla Go
//

import SwiftUI

/// Add/edit form presented as a sheet. Shares the caller's
/// `FavoritePlacesViewModel` instance (never builds its own) so an add from
/// here always lands in the exact same in-memory list every other screen
/// reads — the standalone management screen and the ride-booking picker both
/// pass their own view model in rather than this view constructing one.
///
/// Two ways to supply a coordinate:
/// - Manual entry (default): lat/lng text fields, fully visible and editable
///   — the standalone Saved Places screen's add/edit flow, unchanged.
/// - `lockedCoordinate`: the coordinate comes from elsewhere (e.g. the
///   ride's current destination) and isn't meant to be retyped — the
///   coordinate fields are hidden entirely, not just pre-filled, since a
///   user didn't type them and can't meaningfully edit them here.
struct FavoritePlaceFormView: View {
    @ObservedObject private var viewModel: FavoritePlacesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var address: String
    @State private var latitudeText: String
    @State private var longitudeText: String

    private let editingID: String?
    /// Non-nil only for the locked-coordinate add flow. Mutually exclusive
    /// with editing an existing place (which already owns its coordinate).
    private let lockedCoordinate: Coordinate?

    /// Pass `place` to edit an existing favourite (coordinates editable, as
    /// before). Pass `lockedCoordinate` to add a new favourite from an
    /// already-known coordinate (e.g. the current ride destination) — the
    /// coordinate fields are hidden and the user only names the place.
    /// The two are mutually exclusive; `lockedCoordinate` is ignored when
    /// `place` is provided.
    init(viewModel: FavoritePlacesViewModel, editing place: FavoritePlace? = nil,
         lockedCoordinate: Coordinate? = nil) {
        self.viewModel = viewModel
        self.editingID = place?.id
        self.lockedCoordinate = place == nil ? lockedCoordinate : nil
        _title = State(initialValue: place?.title ?? "")
        _address = State(initialValue: place?.address ?? "")
        let coordinate = place?.coordinate ?? lockedCoordinate
        _latitudeText = State(initialValue: coordinate.map { String($0.latitude) } ?? "")
        _longitudeText = State(initialValue: coordinate.map { String($0.longitude) } ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Place") {
                    TextField("Title (e.g. Home, Work)", text: $title)
                        .accessibilityIdentifier("favorite_place_title_field")
                    TextField("Address", text: $address)
                        .accessibilityIdentifier("favorite_place_address_field")
                }

                if lockedCoordinate == nil {
                    Section("Coordinates") {
                        TextField("Latitude", text: $latitudeText)
                            .keyboardType(.numbersAndPunctuation)
                            .accessibilityIdentifier("favorite_place_latitude_field")
                        TextField("Longitude", text: $longitudeText)
                            .keyboardType(.numbersAndPunctuation)
                            .accessibilityIdentifier("favorite_place_longitude_field")
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("favorite_place_form_error")
                    }
                }
            }
            .navigationTitle(editingID == nil ? "Add Place" : "Edit Place")
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
                            .disabled(!isValid)
                            .accessibilityIdentifier("favorite_place_form_save_button")
                    }
                }
            }
            .onChange(of: viewModel.actionSucceeded) { succeeded in
                if succeeded { dismiss() }
            }
        }
    }

    private var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return lockedCoordinate != nil || (Double(latitudeText) != nil && Double(longitudeText) != nil)
    }

    private func save() {
        guard let coordinate = resolvedCoordinate else { return }
        let place = FavoritePlace(
            id: editingID ?? UUID().uuidString,
            title: title,
            address: address,
            coordinate: coordinate,
            createdAt: Date()
        )
        if let editingID {
            viewModel.update(id: editingID, place)
        } else {
            viewModel.add(place)
        }
    }

    private var resolvedCoordinate: Coordinate? {
        if let lockedCoordinate { return lockedCoordinate }
        guard let latitude = Double(latitudeText), let longitude = Double(longitudeText) else { return nil }
        return Coordinate(latitude: latitude, longitude: longitude)
    }
}

#if DEBUG
struct FavoritePlaceFormView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritePlaceFormView(viewModel: FavoritePlacesDependencies().makeFavoritePlacesViewModel())
    }
}
#endif
