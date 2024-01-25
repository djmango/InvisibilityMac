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

// https://gist.github.com/mayoralito/c2eeeaf4ce9ee9d0845db83ca458929f
extension Color {
    init(_ hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0xFF00) >> 8) / 255.0
        let blue = Double((hex & 0xFF) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
