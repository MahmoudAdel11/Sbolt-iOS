//
//  DriverCard.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import SwiftUI

/// Reusable card showing the matched driver's details.
struct DriverCard: View {
    let driver: Driver
    /// Optional status line (e.g. "Arriving in 4 min").
    var statusText: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: driver.profileImage)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(driver.name).font(.headline)
                    Spacer()
                    Label(String(format: "%.1f", driver.rating), systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
                Text("\(driver.vehicleColor) \(driver.vehicleName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Text(driver.plateNumber)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 6, style: .continuous))
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
        DriverCard(driver: MockTripBookingRepository.sampleDriver(),
                   statusText: "Arriving in 4 min")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
