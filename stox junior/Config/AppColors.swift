import SwiftUI
import UIKit

enum AppColors {

    // MARK: - Backgrounds

    static let background = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.08, blue: 0.07, alpha: 1)
            : UIColor(red: 0.93, green: 0.97, blue: 0.95, alpha: 1)
    })

    static let surface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.14, blue: 0.12, alpha: 1)
            : UIColor.white
    })

    static let surfaceSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.19, blue: 0.17, alpha: 1)
            : UIColor(red: 0.91, green: 0.96, blue: 0.93, alpha: 1)
    })

    static let sheetBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.10, blue: 0.09, alpha: 1)
            : UIColor(red: 0.95, green: 0.98, blue: 0.97, alpha: 1)
    })

    // MARK: - Text

    static let textPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.97, blue: 0.94, alpha: 1)
            : UIColor(red: 0.07, green: 0.17, blue: 0.13, alpha: 1)
    })

    static let textSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.76, blue: 0.68, alpha: 1)
            : UIColor(red: 0.35, green: 0.50, blue: 0.44, alpha: 1)
    })

    static let textTertiary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.38, green: 0.54, blue: 0.48, alpha: 1)
            : UIColor(red: 0.56, green: 0.68, blue: 0.63, alpha: 1)
    })

    // MARK: - Brand

    static let accent = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.82, blue: 0.70, alpha: 1)
            : UIColor(red: 0.09, green: 0.68, blue: 0.57, alpha: 1)
    })

    static let accentDeep = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.58, blue: 0.49, alpha: 1)
            : UIColor(red: 0.04, green: 0.38, blue: 0.32, alpha: 1)
    })

    // MARK: - Semantic

    static let gain = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.84, blue: 0.58, alpha: 1)
            : UIColor(red: 0.10, green: 0.62, blue: 0.43, alpha: 1)
    })

    static let loss = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.42, blue: 0.44, alpha: 1)
            : UIColor(red: 0.88, green: 0.25, blue: 0.28, alpha: 1)
    })

    static let warning = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.78, blue: 0.14, alpha: 1)
            : UIColor(red: 0.96, green: 0.63, blue: 0.08, alpha: 1)
    })

    static let highlight = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.90, blue: 0.22, alpha: 1)
            : UIColor(red: 0.92, green: 0.76, blue: 0.08, alpha: 1)
    })

    // MARK: - UI Chrome

    static let divider = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.26, blue: 0.23, alpha: 1)
            : UIColor(red: 0.82, green: 0.91, blue: 0.87, alpha: 1)
    })

    static let cardBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.24, blue: 0.21, alpha: 1)
            : UIColor(red: 0.80, green: 0.90, blue: 0.85, alpha: 1)
    })

    static let inputBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.21, blue: 0.18, alpha: 1)
            : UIColor(red: 0.87, green: 0.94, blue: 0.91, alpha: 1)
    })

    // MARK: - Contextual

    static let indigo = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.52, green: 0.58, blue: 0.98, alpha: 1)
            : UIColor(red: 0.35, green: 0.40, blue: 0.85, alpha: 1)
    })

    static let purple = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.70, green: 0.48, blue: 0.96, alpha: 1)
            : UIColor(red: 0.55, green: 0.33, blue: 0.82, alpha: 1)
    })

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
