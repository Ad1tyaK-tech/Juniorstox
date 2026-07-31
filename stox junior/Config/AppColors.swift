import SwiftUI
import UIKit


private func adaptive(
    lightR: Double, lightG: Double, lightB: Double,
    darkR: Double, darkG: Double, darkB: Double
) -> Color {
#if canImport(UIKit)
    Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: darkR, green: darkG, blue: darkB, alpha: 1)
            : UIColor(red: lightR, green: lightG, blue: lightB, alpha: 1)
    })
#elseif canImport(AppKit)
    Color(NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: darkR, green: darkG, blue: darkB, alpha: 1)
            : NSColor(red: lightR, green: lightG, blue: lightB, alpha: 1)
    })
#else
    Color(red: lightR, green: lightG, blue: lightB)
#endif
}

enum AppColors {

    // MARK: - Backgrounds

    static let background = adaptive(
        lightR: 0.93, lightG: 0.97, lightB: 0.95,
        darkR: 0.06, darkG: 0.08, darkB: 0.07
    )

    static let surface = adaptive(
        lightR: 1.00, lightG: 1.00, lightB: 1.00,
        darkR: 0.11, darkG: 0.14, darkB: 0.12
    )

    static let surfaceSecondary = adaptive(
        lightR: 0.91, lightG: 0.96, lightB: 0.93,
        darkR: 0.15, darkG: 0.19, darkB: 0.17
    )

    static let sheetBackground = adaptive(
        lightR: 0.95, lightG: 0.98, lightB: 0.97,
        darkR: 0.08, darkG: 0.10, darkB: 0.09
    )

    // MARK: - Text

    static let textPrimary = adaptive(
        lightR: 0.07, lightG: 0.17, lightB: 0.13,
        darkR: 0.92, darkG: 0.97, darkB: 0.94
    )

    static let textSecondary = adaptive(
        lightR: 0.35, lightG: 0.50, lightB: 0.44,
        darkR: 0.55, darkG: 0.76, darkB: 0.68
    )

    static let textTertiary = adaptive(
        lightR: 0.56, lightG: 0.68, lightB: 0.63,
        darkR: 0.38, darkG: 0.54, darkB: 0.48
    )

    // MARK: - Brand

    static let accent = adaptive(
        lightR: 0.09, lightG: 0.68, lightB: 0.57,
        darkR: 0.12, darkG: 0.82, darkB: 0.70
    )

    static let accentDeep = adaptive(
        lightR: 0.04, lightG: 0.38, lightB: 0.32,
        darkR: 0.08, darkG: 0.58, darkB: 0.49
    )

    // MARK: - Semantic

    static let gain = adaptive(
        lightR: 0.10, lightG: 0.62, lightB: 0.43,
        darkR: 0.20, darkG: 0.84, darkB: 0.58
    )

    static let loss = adaptive(
        lightR: 0.88, lightG: 0.25, lightB: 0.28,
        darkR: 1.00, darkG: 0.42, darkB: 0.44
    )

    static let warning = adaptive(
        lightR: 0.96, lightG: 0.63, lightB: 0.08,
        darkR: 1.00, darkG: 0.78, darkB: 0.14
    )

    static let highlight = adaptive(
        lightR: 0.92, lightG: 0.76, lightB: 0.08,
        darkR: 1.00, darkG: 0.90, darkB: 0.22
    )

    // MARK: - UI Chrome

    static let divider = adaptive(
        lightR: 0.82, lightG: 0.91, lightB: 0.87,
        darkR: 0.20, darkG: 0.26, darkB: 0.23
    )

    static let cardBorder = adaptive(
        lightR: 0.80, lightG: 0.90, lightB: 0.85,
        darkR: 0.18, darkG: 0.24, darkB: 0.21
    )

    static let inputBackground = adaptive(
        lightR: 0.87, lightG: 0.94, lightB: 0.91,
        darkR: 0.16, darkG: 0.21, darkB: 0.18
    )

    // MARK: - Contextual

    static let indigo = adaptive(
        lightR: 0.35, lightG: 0.40, lightB: 0.85,
        darkR: 0.52, darkG: 0.58, darkB: 0.98
    )

    static let purple = adaptive(
        lightR: 0.55, lightG: 0.33, lightB: 0.82,
        darkR: 0.70, darkG: 0.48, darkB: 0.96
    )

    // MARK: - Welcome Screen Gradient (kept consistent across modes)

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
