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

    init(rideID: String, dependencies: TripBookingDependencies = TripBookingDependencies()) {
        _viewModel = StateObject(wrappedValue: dependencies.makeRatingSubmissionViewModel(rideID: rideID))
    }

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 50, height: 6)

            Image(systemName: "flag.checkered")
                .font(.system(size: 40))
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text("How was your ride?")
                .font(.title2).bold()

            starPicker

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("rating_error_message")
            }

            Button {
                viewModel.submit(score: selectedScore)
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Text("Submit")
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedScore == 0 || viewModel.isSubmitting)
            .accessibilityIdentifier("rating_submit_button")

            Button("Skip") { dismiss() }
                .disabled(viewModel.isSubmitting)
                .accessibilityIdentifier("rating_skip_button")
        }
        .padding(24)
        .interactiveDismissDisabled(viewModel.isSubmitting)
        .onChange(of: viewModel.didSubmit) { didSubmit in
            if didSubmit { dismiss() }
        }
    }

    private var starPicker: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= selectedScore ? "star.fill" : "star")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)
                    .onTapGesture { selectedScore = star }
                    .accessibilityIdentifier("rating_star_\(star)")
            }
        }
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
        RatingSubmissionView(rideID: "ride-1")
    }
}
#endif
