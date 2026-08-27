//
//  RatingSubmissionView.swift
//  Yalla Go
//

import SwiftUI

/// Post-ride rating prompt, presented as a sheet over `TripBookingStatusView`'s
/// `.completed` state. A tappable 1-5 star picker + Submit, plus a Skip
/// affordance — rating is optional, so both paths just dismiss; the caller
/// (`TripBookingStatusView`) resumes the normal auto-dismiss flow via
/// `.sheet`'s `onDismiss`, regardless of which path got there.
struct RatingSubmissionView: View {
    @StateObject private var viewModel: RatingSubmissionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedScore = 0

    /// Driver name + fare are display-only, sourced from the `Trip` the
    /// caller already has in hand (`TripBookingStatusView`'s `.completed`
    /// phase) — not fetched here. `RatingSubmissionViewModel` itself still
    /// only knows the ride ID, unchanged: submitting a rating needs nothing
    /// else.
    private let driverName: String?
    private let fare: Double

    init(rideID: String, driverName: String?, fare: Double,
         dependencies: TripBookingDependencies = TripBookingDependencies()) {
        _viewModel = StateObject(wrappedValue: dependencies.makeRatingSubmissionViewModel(rideID: rideID))
        self.driverName = driverName
        self.fare = fare
    }

    var body: some View {
        VStack {
            Capsule()
                .fill(AppColors.borderHairline)
                .frame(width: 50, height: 6)
                .padding(.top, AppSpacing.sm)

            Spacer()

            VStack(spacing: AppSpacing.lg) {
                completedIcon

                VStack(spacing: AppSpacing.xs) {
                    Text("TRIP COMPLETED · \(fare.toCurrency())")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.accent)

                    Text("How was \(driverName ?? "your driver")'s ride?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Your feedback helps improve the community")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textMuted)
                }

                starPicker

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.danger)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("rating_error_message")
                }
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            VStack(spacing: AppSpacing.md) {
                Button {
                    viewModel.submit(score: selectedScore)
                } label: {
                    ZStack {
                        Text("Submit rating")
                            .font(.subheadline.weight(.semibold))
                            .opacity(viewModel.isSubmitting ? 0 : 1)
                        if viewModel.isSubmitting {
                            ProgressView().tint(AppColors.textOnAccent)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .foregroundStyle(AppColors.textOnAccent)
                .background(AppColors.textPrimary, in: Capsule())
                .disabled(selectedScore == 0 || viewModel.isSubmitting)
                .opacity(selectedScore == 0 ? 0.5 : 1)
                .accessibilityIdentifier("rating_submit_button")

                Button("Skip for now") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textMuted)
                    .disabled(viewModel.isSubmitting)
                    .accessibilityIdentifier("rating_skip_button")
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)
        }
        .frame(maxHeight: .infinity)
        .interactiveDismissDisabled(viewModel.isSubmitting)
        .onChange(of: viewModel.didSubmit) { didSubmit in
            if didSubmit { dismiss() }
        }
    }

    private var completedIcon: some View {
        ZStack {
            Circle().fill(AppColors.accent)
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.textOnAccent)
        }
        .frame(width: 72, height: 72)
        .shadow(color: AppColors.accent.opacity(0.35), radius: 12, x: 0, y: 6)
        .accessibilityHidden(true)
    }

    private var starPicker: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= selectedScore ? "star.fill" : "star")
                    .font(.system(size: 34))
                    .foregroundStyle(star <= selectedScore ? AppColors.ratingGold : AppColors.borderHairline)
                    .onTapGesture { selectedScore = star }
                    .accessibilityIdentifier("rating_star_\(star)")
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rating: \(selectedScore) out of 5 stars")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: selectedScore = min(5, selectedScore + 1)
            case .decrement: selectedScore = max(0, selectedScore - 1)
            @unknown default: break
            }
        }
    }
}

#if DEBUG
struct RatingSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        RatingSubmissionView(rideID: "ride-1", driverName: "Jane Driver", fare: 42.5)
    }
}
#endif
