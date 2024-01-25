//
//  UIColor+Hex.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import Foundation
import SwiftUI

// prefix operator ⋮
// prefix func ⋮(hex:UInt32) -> Color {
//     return Color(hex)
// }

extension Color {
    init(_ hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0xFF00) >> 8) / 255.0
        let blue = Double((hex & 0xFF) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
