//
//  TripCard.swift
//  Yalla Go
//

import SwiftUI

/// Reusable card summarising a single ride in any lifecycle state. The
/// backend has no fare/distance/duration/location-name fields, so this shows
/// coordinates and status only.
struct TripCard: View {
    let trip: Trip
    var formatter = TripFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topRow
            route
            Divider()
            bottomRow
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Pieces

    private var topRow: some View {
        HStack {
            Label("Ride", systemImage: "car.fill")
                .font(.subheadline.weight(.semibold))
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(trip.status.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15), in: Capsule())
            .foregroundStyle(statusColor)
    }

    private var route: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 2) {
                Image(systemName: "circle.fill").font(.system(size: 8)).foregroundStyle(.secondary)
                Rectangle().fill(Color.secondary.opacity(0.4)).frame(width: 1, height: 18)
                Image(systemName: "mappin.circle.fill").font(.system(size: 10)).foregroundStyle(Color.accentColor)
            }
            .accessibilityHidden(true)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                Text(formatter.coordinate(trip.pickupCoordinate)).font(.subheadline)
                Text(formatter.coordinate(trip.destinationCoordinate)).font(.subheadline)
            }
            Spacer(minLength: 0)
        }
    }

    private var bottomRow: some View {
        Text("\(formatter.date(trip.requestedAt)) · \(formatter.time(trip.requestedAt))")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var statusColor: Color {
        switch trip.status {
        case .completed: return .green
        case .cancelled: return .red
        case .ongoing:   return .blue
        case .accepted:  return .orange
        case .requested: return .secondary
        }
    }

    private var accessibilitySummary: String {
        "Ride from \(formatter.coordinate(trip.pickupCoordinate)) to "
            + "\(formatter.coordinate(trip.destinationCoordinate)), "
            + "\(formatter.date(trip.requestedAt)), \(trip.status.displayName)"
    }
}

#if DEBUG
struct TripCard_Previews: PreviewProvider {
    static var previews: some View {
        TripCard(trip: MockTripRepository.sampleTrips()[0])
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
