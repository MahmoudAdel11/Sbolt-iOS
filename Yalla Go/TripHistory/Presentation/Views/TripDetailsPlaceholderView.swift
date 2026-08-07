//
//  TripDetailsPlaceholderView.swift
//  Yalla Go
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
                detailRow("Pickup", formatter.coordinate(trip.pickupCoordinate), systemImage: "circle.fill")
                detailRow("Destination", formatter.coordinate(trip.destinationCoordinate), systemImage: "mappin.circle.fill")
            }
            Section("Status") {
                detailRow("Status", trip.status.displayName, systemImage: "info.circle")
                detailRow("Requested", "\(formatter.date(trip.requestedAt)) · \(formatter.time(trip.requestedAt))",
                          systemImage: "calendar")
                if let acceptedAt = trip.acceptedAt {
                    detailRow("Accepted", "\(formatter.date(acceptedAt)) · \(formatter.time(acceptedAt))",
                              systemImage: "checkmark.circle")
                }
                if let completedAt = trip.completedAt {
                    detailRow("Completed", "\(formatter.date(completedAt)) · \(formatter.time(completedAt))",
                              systemImage: "flag.checkered")
                }
                if let cancelledAt = trip.cancelledAt {
                    detailRow("Cancelled", "\(formatter.date(cancelledAt)) · \(formatter.time(cancelledAt))",
                              systemImage: "xmark.circle")
                }
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
