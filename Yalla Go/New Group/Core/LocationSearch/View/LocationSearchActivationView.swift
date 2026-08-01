//
//  LocationSearchActivationView.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/01/2025.
//

import SwiftUI

struct LocationSearchActivationView: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.black)
                .frame(width: 8, height: 8)
                .padding(.leading)

            Text("To Where?")
                .foregroundColor(Color(.darkGray))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

struct LocationSearchActivationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchActivationView()
    }
}
