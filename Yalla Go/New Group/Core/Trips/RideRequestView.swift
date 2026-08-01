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
    @StateObject private var bookingViewModel = TripBookingDependencies().makeTripBookingViewModel()

    var body: some View {
        Group {
            if bookingViewModel.isIdle {
                bookingForm
            } else {
                TripBookingStatusView(viewModel: bookingViewModel)
                    .background(
                        BottomSheetShape(radius: 20)
                            .fill(Color.white)
                    )
                    .background(
                        Color.white
                            .ignoresSafeArea(.container, edges: .bottom)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: bookingViewModel.isIdle)
    }

    // The original ride-request card. Shown while no booking is in progress.
    private var bookingForm: some View {
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
            Text("SUGGESTED RIDES")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding()
                .foregroundColor(.gray)
                .frame(maxWidth:.infinity , alignment: .leading)
                        
            
            
            ScrollView(.horizontal, showsIndicators: false){
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
            Button {
                bookingViewModel.confirmTrip()
            } label: {
                Text("CONFIRM RIDE")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            BottomSheetShape(radius: 20)
                .fill(Color.white)
        )
        .background(
            Color.white
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
    }
}
                    
             


/// Rounds only the top-left and top-right corners so the sheet merges
/// seamlessly with the Tab Bar below it.
private struct BottomSheetShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

struct RideRequestView_Previews: PreviewProvider {
    static var previews: some View {
        RideRequestView()
    }
}
