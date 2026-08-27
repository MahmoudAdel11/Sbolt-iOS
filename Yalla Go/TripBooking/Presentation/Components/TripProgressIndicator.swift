//
//  TripProgressIndicator.swift
//  Yalla Go
//

import SwiftUI

/// Segmented progress bar for the active-trip status bar.
///
/// DESIGN NOTE: the mockup described an example with an "arriving" step, but
/// `TripStatus` has exactly three non-terminal states a trip actually passes
/// through while active — `.requested`, `.accepted`, `.ongoing`
/// (`.completed`/`.cancelled` are terminal and exit this screen entirely).
/// There is no real "arriving" state anywhere in the domain model. Rather
/// than fabricate a 4th segment with nothing backing it, or collapse to an
/// uninformative 2-segment "in-progress vs arriving" bar that can't actually
/// distinguish those, this renders 3 segments mapped directly to the 3 real
/// states — honest to what the app can actually observe.
struct TripProgressIndicator: View {
    let status: TripStatus

    private static let segments: [TripStatus] = [.requested, .accepted, .ongoing]

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(Array(Self.segments.enumerated()), id: \.offset) { index, _ in
                Capsule()
                    .fill(isFilled(index) ? AppColors.accentTint : AppColors.textOnAccent.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trip progress")
        .accessibilityValue(status.displayName)
    }

    private func isFilled(_ index: Int) -> Bool {
        guard let currentIndex = Self.segments.firstIndex(of: status) else { return false }
        return index <= currentIndex
    }
}

#if DEBUG
struct TripProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach([TripStatus.requested, .accepted, .ongoing], id: \.self) { status in
                TripProgressIndicator(status: status)
            }
        }
        .padding()
        .background(AppColors.accent)
        .previewLayout(.sizeThatFits)
    }
}
#endif
