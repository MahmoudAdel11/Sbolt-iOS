//
//  LocationSearchView.swift
//  Yalla Go
//
//  Created by Mahmoud on 31/01/2025.
//

import SwiftUI

struct LocationSearchView: View {
    @State private var  startLocationText = ""
    @Binding var mapState: MapViewState
    @EnvironmentObject var viewModel : LocationSearchViewModel // CASTING OBJECT .............................
    
    var body: some View {
        VStack{
            HStack{
                VStack{
                    Circle()
                        .fill(Color(.systemGray))
                        .frame(width: 6, height: 6)
                    Rectangle()
                        .fill(Color(.systemGray))
                        .frame(width: 1, height: 24)
                    Rectangle()
                        .fill(Color(.black))
                        .frame(width: 6, height: 6)
                    
                }
                
                VStack {
                    TextField("Current location",text: $startLocationText)
                        .frame(height: 30)
                        .background(Color(.systemGroupedBackground))
                        .padding(.trailing)
                    TextField("Where to ?",text: $viewModel.queryFragment)
                        .frame(height: 30)
                        .background(Color(.systemGray3))
                        .padding(.trailing)
                    
                }
            }
            .padding(.horizontal)
            .padding(.top,65)
            
            Divider()
                .padding(.vertical)
           
            
            ScrollView{
                VStack(alignment: .leading){
                    //////////////////////////////////////////////////////////////////////////////////////////////////////
                    ForEach(viewModel.results, id: \.self) {
                        result in
                        LocationSearchResultCell(title: result.title, subtitle: result.subtitle)
                            .onTapGesture {
                                withAnimation(.spring()){
                                    viewModel.selecteLocation(result)
                                    mapState = .locationSelected
                                }
                            }
                    }
                }
            }
        }
        .background(.white)
    }
}

struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchView(mapState: .constant(.searchingForLocation))
    }
}
