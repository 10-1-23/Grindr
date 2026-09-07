//
//  Theme.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

enum Theme {
    // CANON Palette: Slate-Black ruthless simplicity
    static let background = Color(hex: "070a12")
    static let surface = Color(hex: "0f1422")
    static let surfaceElevated = Color(hex: "171f33")
    static let surfaceBorder = Color(hex: "212b45")
    
    // Accents
    static let accent = Color(hex: "ffd200")       // Classic Grindr Gold
    static let accentSecondary = Color(hex: "38bdf8")
    static let onlineGreen = Color(hex: "10b981")   // Live pulse green
    static let textPrimary = Color(hex: "f8fafc")
    static let textSecondary = Color(hex: "94a3b8")
    static let textMuted = Color(hex: "64748b")
    static let danger = Color(hex: "ef4444")
    
    // Typography
    static let fontMono = Font.system(.caption, design: .monospaced)
    static let fontHeadline = Font.system(.headline, design: .default).weight(.bold)
    static let fontTitle = Font.system(.title2, design: .default).weight(.black)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(a) / 255,
            opacity: Double(a) / 255
        )
    }
}
