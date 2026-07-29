//
//  TripDetailsPlaceholderView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Minimal trip-details screen used to verify navigation from the history list.
/// A full details feature is intentionally out of scope.
struct TripDetailsPlaceholderView: View {
    let trip: Trip
    private let formatter = TripFormatter()

    var body: some View {
        List {
            Section("Route") {
                detailRow("Pickup", trip.pickupLocationName, systemImage: "circle.fill")
                detailRow("Destination", trip.destinationLocationName, systemImage: "mappin.circle.fill")
            }
            Section("Details") {
                detailRow("Price", formatter.price(trip.price), systemImage: "creditcard")
                detailRow("Distance", formatter.distance(meters: trip.distance), systemImage: "ruler")
                detailRow("Duration", formatter.duration(seconds: trip.duration), systemImage: "clock")
                detailRow("Date", "\(formatter.date(trip.completedAt)) · \(formatter.time(trip.completedAt))",
                          systemImage: "calendar")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("trip_details_placeholder")
    }

    private func detailRow(_ title: String, _ value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

#if DEBUG
struct TripDetailsPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TripDetailsPlaceholderView(trip: MockTripRepository.sampleTrips()[0])
        }
        .navigationViewStyle(.stack)
    }
}
#endif
