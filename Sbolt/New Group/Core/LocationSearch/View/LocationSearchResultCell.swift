//
//  LocationSearchResultCell.swift
//  Yalla Go
//
//  Created by Mahmoud on 31/01/2025.
//

import SwiftUI

struct LocationSearchResultCell: View {
    let title  : String
    let subtitle : String
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 36, height: 36)
                Image(systemName: "mappin")
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(AppColors.accentTextDark)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.accentTextSecondary)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.accentTint, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

struct LocationSearchResultCell_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchResultCell(title: "alex", subtitle: "123 main")
    }
}
    
