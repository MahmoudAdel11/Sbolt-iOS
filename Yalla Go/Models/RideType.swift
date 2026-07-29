//
//  RideType.swift
//  Yalla Go
//
//  Created by Mahmoud on 15/03/2025.
//

import Foundation

enum RideType: Int, CaseIterable, Identifiable {
    
    case uberX
    case black
    case uberXL
    
    var id: Int { return rawValue }
    
    var description: String {
        switch self {
        case.uberX: return "YallaX"
        case.black: return "YallaBlack"
        case.uberXL: return "YallaComfort"
        }
    }
    
    var imageName: String{
        switch self {
        case.uberX: return "yallaGoXIcon"
        case .black: return "yallaGo-black"
        case.uberXL: return "yallaGoXIcon"
        }
    }
    
    var baseFare: Double{
        switch self {
        case.uberX: return 5
        case .black: return 20
        case.uberXL: return 10
        }
    }
    func computePrice(for distanceInMeters : Double) ->  Double{
        let distanceInMiles = distanceInMeters / 1600
        
        switch self {
        case.uberX: return distanceInMiles * 1.5 + baseFare
        case .black: return distanceInMiles * 2.0 + baseFare
        case.uberXL: return distanceInMiles * 1.75 + baseFare
        }
      
    }
}


