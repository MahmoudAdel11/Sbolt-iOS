//
//  MapActionButton.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/01/2025.
//

import SwiftUI

struct MapActionButton: View {
    @Binding var mapState: MapViewState
    @EnvironmentObject var viewModel:LocationSearchViewModel
    var body: some View {
        Button{
            withAnimation(.spring()){
                actionForState(mapState)
            }
        }label: {
            Image  (systemName: imageNameForState(mapState))
                .font(.title2)
                .foregroundColor(.black)
                .padding()
                .background(.white)
                .clipShape(Circle())
                .shadow(color: .black, radius:6)
        }
        .frame( maxWidth: .infinity, alignment: .leading)
    }
    
    func actionForState(_ state:MapViewState){
        switch state {
        case .noInput:
            print("NOTE: no input")
        case .searchingForLocation:
            mapState = .noInput
        case .locationSelected:
            print("NOTE: clear  map view")
            mapState = .noInput
            viewModel.clearSelectedLocation()
            

        }
    }
    func imageNameForState(_ state:MapViewState)->String{
        switch state {
        case .noInput:
            return "line.3.horizontal"
        case .searchingForLocation , .locationSelected:
            return "arrow.left"

        }
    }
    
}

struct MapActionButton_Previews: PreviewProvider {
    static var previews: some View {
        MapActionButton(mapState: .constant(.noInput))
    }
}
