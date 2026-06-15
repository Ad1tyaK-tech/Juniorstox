import SwiftUI

enum AppColors {
    // Backgrounds
    static let background       = Color(red: 0.93, green: 0.97, blue: 0.95)
    static let surface          = Color.white
    static let surfaceSecondary = Color(red: 0.91, green: 0.96, blue: 0.93)
    static let sheetBackground  = Color(red: 0.95, green: 0.98, blue: 0.97)

    // Text
    static let textPrimary      = Color(red: 0.07, green: 0.17, blue: 0.13)
    static let textSecondary    = Color(red: 0.35, green: 0.50, blue: 0.44)
    static let textTertiary     = Color(red: 0.56, green: 0.68, blue: 0.63)

    // Brand
    static let accent           = Color(red: 0.09, green: 0.68, blue: 0.57)
    static let accentDeep       = Color(red: 0.04, green: 0.38, blue: 0.32)

    // Semantic
    static let gain             = Color(red: 0.10, green: 0.62, blue: 0.43)
    static let loss             = Color(red: 0.88, green: 0.25, blue: 0.28)
    static let warning          = Color(red: 0.96, green: 0.63, blue: 0.08)
    static let highlight        = Color(red: 0.92, green: 0.76, blue: 0.08)

    // UI chrome
    static let divider          = Color(red: 0.82, green: 0.91, blue: 0.87)
    static let cardBorder       = Color(red: 0.80, green: 0.90, blue: 0.85)
    static let inputBackground  = Color(red: 0.87, green: 0.94, blue: 0.91)

    // Contextual
    static let indigo           = Color(red: 0.35, green: 0.40, blue: 0.85)
    static let purple           = Color(red: 0.55, green: 0.33, blue: 0.82)

    // Welcome screen gradient
    static let welcomeGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.35, blue: 0.30),
            Color(red: 0.09, green: 0.58, blue: 0.50),
            Color(red: 0.18, green: 0.75, blue: 0.64)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
