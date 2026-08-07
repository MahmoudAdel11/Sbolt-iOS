//
//  DriverCard.swift
//  Yalla Go
//

import SwiftUI

/// Reusable card showing whatever driver details are actually available.
/// The backend only ever exposes a bare `driver_id` — every rich field is
/// optional, so this renders a graceful fallback ("Driver assigned") instead
/// of leaving gaps where a name/rating/vehicle would go.
struct DriverCard: View {
    let driver: Driver
    /// Optional status line (e.g. "Arriving in 4 min").
    var statusText: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: driver.profileImage ?? "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(driver.name ?? "Driver assigned").font(.headline)
                    Spacer()
                    if let rating = driver.rating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                if let vehicleName = driver.vehicleName {
                    Text([driver.vehicleColor, vehicleName].compactMap { $0 }.joined(separator: " "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    if let plateNumber = driver.plateNumber {
                        Text(plateNumber)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    Spacer()
                    if let statusText {
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct DriverCard_Previews: PreviewProvider {
    static var previews: some View {
        DriverCard(driver: Driver(id: "driver-1"), statusText: "Driver on the way")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
