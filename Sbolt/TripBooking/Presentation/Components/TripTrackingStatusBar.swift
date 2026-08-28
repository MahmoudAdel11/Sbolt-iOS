//
//  TripTrackingStatusBar.swift
//  Yalla Go
//

import SwiftUI

/// Floating status card overlaying the map while a ride is active — driver
/// name + a short status line, and the 3-segment `TripProgressIndicator`.
/// Purely presentational: reads the already-published `Trip`, sends nothing.
struct TripTrackingStatusBar: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(statusLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textOnAccent)
                .lineLimit(1)

            TripProgressIndicator(status: trip.status)
        }
        .padding(AppSpacing.md)
        .background(AppColors.accent, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityElement(children: .combine)
    }

    /// No real ETA exists anywhere in the domain model (`Driver.
    /// estimatedArrivalMinutes` has no backend source — see `Driver.swift`'s
    /// own doc comment), so this states what's actually known (driver name +
    /// lifecycle status) rather than fabricating a countdown. See this
    /// task's summary for the flagged "Logic change needed" item.
    private var statusLine: String {
        let name = trip.driver?.name ?? "Your driver"
        switch trip.status {
        case .requested: return "Looking for a nearby driver…"
        case .accepted: return "\(name) is on the way"
        case .ongoing: return "\(name) is taking you there"
        case .completed, .cancelled: return trip.status.displayName
        }
    }
}

#if DEBUG
struct TripTrackingStatusBar_Previews: PreviewProvider {
    static var previews: some View {
        TripTrackingStatusBar(trip: MockTripRepository.sampleTrips()[0])
            .padding()
            .background(Color.gray.opacity(0.2))
            .previewLayout(.sizeThatFits)
    }
}
#endif
