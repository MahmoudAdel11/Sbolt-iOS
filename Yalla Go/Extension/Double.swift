//
//  Double.swift
//  Yalla Go
//
//  Created by Mahmoud on 26/03/2025.
//

import Foundation
extension Double {
    private var currencyFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter
    }
    
    func toCurrency() -> String {
        return (currencyFormatter.string(for: self) ?? "" ) + " EGP" 
    }
}

    
