//
//  LocationSearchView.swift
//  Yalla Go
//
//  Created by Mahmoud on 31/01/2025.
//

import SwiftUI

struct LocationSearchView: View {
    @Binding var mapState: MapViewState
    @EnvironmentObject var viewModel : LocationSearchViewModel // CASTING OBJECT .............................

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            currentLocationRow

            searchField

            if !viewModel.results.isEmpty {
                Text("Suggestions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.lg)
            }

            ScrollView {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.results, id: \.self) { result in
                        LocationSearchResultCell(title: result.title, subtitle: result.subtitle)
                            .onTapGesture {
                                withAnimation(.spring()){
                                    viewModel.selecteLocation(result)
                                    mapState = .locationSelected
                                }
                            }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .padding(.top, 65)
        .background(AppColors.backgroundPrimary)
    }

    /// A small accent dot rather than an editable field — the app already
    /// tracks the rider's real current location (`LocationManager`); this
    /// row is a display, not a second location input.
    private var currentLocationRow: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(AppColors.accent)
                .frame(width: 8, height: 8)
            Text("Current location")
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 44)
        .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .padding(.horizontal, AppSpacing.lg)
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.accent)
            TextField("Search destination", text: $viewModel.queryFragment)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 40) // compact — smaller than a standard 50pt control
        .background(AppColors.accentTint, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.accent, lineWidth: 1.5)
        )
        .padding(.horizontal, AppSpacing.lg)
    }
}

struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchView(mapState: .constant(.searchingForLocation))
    }
}
