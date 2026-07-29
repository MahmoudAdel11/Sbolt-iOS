//
//  LocationSearchActivationView.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/01/2025.
//

import SwiftUI

struct LocationSearchActivationView: View {
    var body: some View {
        HStack{
            Rectangle()
                .fill(Color.black)
                // .padding(.horizontal) why white  ??????????????????????????
                .frame(width: 8 , height: 8)
                .padding(.horizontal)

            Text("To Where ?")
                .foregroundColor(Color(.darkGray))
             Spacer()
        }
        .frame(width: UIScreen.main.bounds.width - 65, height: 50 )
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: .black, radius: 6)
            
        
        )
        
    }
}

struct LocationSearchActivationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchActivationView()
    }
}
