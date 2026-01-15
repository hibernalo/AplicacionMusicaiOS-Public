//
//  Color+Extensions.swift
//  AplicacionMusicaiOS
//

import SwiftUI

extension Color {
    static let primaryBlue = Color(hex: 0x1E88E5)
    static let darkGray = Color(hex: 0x424242)
    static let lightGray = Color(hex: 0xBDBDBD)

    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
