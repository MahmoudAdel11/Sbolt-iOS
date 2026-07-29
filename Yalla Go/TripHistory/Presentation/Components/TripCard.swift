//
//  TripCard.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Reusable card summarising a single completed trip.
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
            Label(trip.tripType.description, systemImage: "car.fill")
                .font(.subheadline.weight(.semibold))
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(trip.status.rawValue.capitalized)
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
                Text(trip.pickupLocationName).font(.subheadline)
                Text(trip.destinationLocationName).font(.subheadline)
            }
            Spacer(minLength: 0)
        }
    }

    private var bottomRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(formatter.date(trip.completedAt)) · \(formatter.time(trip.completedAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatter.distance(meters: trip.distance))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatter.price(trip.price))
                .font(.headline)
        }
    }

    private var statusColor: Color {
        switch trip.status {
        case .completed: return .green
        case .cancelled: return .red
        }
    }

    private var accessibilitySummary: String {
        "\(trip.tripType.description) trip from \(trip.pickupLocationName) to "
            + "\(trip.destinationLocationName), \(formatter.price(trip.price)), "
            + "\(formatter.distance(meters: trip.distance)), "
            + "\(formatter.date(trip.completedAt)), \(trip.status.rawValue)"
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
