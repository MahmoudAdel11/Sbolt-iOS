//
//  RideRequestView.swift
//  Yalla Go
//
//  Created by Mahmoud on 09/03/2025.
//

import SwiftUI

struct RideRequestView: View {
    @State private var selectedRideType: RideType =  .uberX
    @EnvironmentObject var locationViewModel:LocationSearchViewModel

    var body: some View {
        VStack{
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 50, height: 6)
                .padding(.top,8)
            // trip info
            HStack{
                VStack{
                    Circle()
                        .fill(Color(.systemGray))
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color(.systemGray))
                        .frame(width: 1, height: 32)
                    Rectangle()
                        .fill(Color(.black))
                        .frame(width: 8, height: 8)
                }
                
                VStack(alignment: .leading, spacing: 24){
                    HStack{
                        Text("Current location" )
                            .font(.system(size: 16, weight: .semibold ))
                            .foregroundColor(Color(.gray))
                        Spacer()
                        Text(locationViewModel.pickupTime ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.gray))
                    }.padding(.bottom,10)
                                            
                    HStack{
                        if let location = locationViewModel.selectedYallaGoLocation {
                            Text(location.titel)
                                .font(.system(size: 16, weight: .semibold  ))
                        }
                        Spacer()
                        Text(locationViewModel.dropoffTime ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.gray))
                    }
                }
                .padding(.leading,8)
                                            
            } .padding()
            Divider()
            // ride type
            Text(" SUCCESTED RIDES")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding()
                .foregroundColor(.gray)
                .frame(maxWidth:.infinity , alignment: .leading)
                        
            
            
            ScrollView(.horizontal){
                HStack(spacing: 12){
                    ForEach(RideType.allCases ){ type in
                        VStack(alignment: .leading) {
                            Image(type.imageName)
                                .resizable()
                                .scaledToFit()
                            VStack( alignment : .leading, spacing: 4){
                                Text(type.description)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(locationViewModel.computeRidePrice(forType: type).toCurrency())
                                    .font(.system(size: 14, weight: .semibold))
                            }.padding()
                        }
                        .frame(width: 120, height: 140)
                        .foregroundColor(type ==
                                         selectedRideType ? .white : .black)
                        .background(Color(
                            type == selectedRideType ?
                                .systemBlue :
                                .systemGroupedBackground))
                        .scaleEffect(type == selectedRideType ? 1.2 : 1.0)
                    .cornerRadius(10)
                    .onTapGesture {
                        withAnimation(.spring()){
                            selectedRideType = type
                        }
                    }
                    }
                    
                }
            }.padding(.horizontal)
            
            
            
            
            Divider()
                .padding(.vertical, 8)
            
        // payment
            HStack( spacing: 12){
            Text("visa")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(6)
                    .background(.blue)
                    .cornerRadius(4)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                Text("*****  123").fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .imageScale(.medium)
                    .padding()
            }
            .frame(height: 50)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        
                        // confirm trip
            Button{
                
            }label: {
                Text("CONFIRM RIDE")
                    .fontWeight(.bold)
                    .frame(width: UIScreen.main.bounds
                        .width - 32, height: 50)
                    .background(.blue)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            
        }
        .padding(.bottom,25)
        .background(.white)
        .cornerRadius( 16)
         
    }
}
                    
             


struct RideRequestView_Previews: PreviewProvider {
    static var previews: some View {
        RideRequestView()
    }
}
