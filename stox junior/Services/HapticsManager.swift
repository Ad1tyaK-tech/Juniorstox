import UIKit

struct HapticsManager {
    static var isDisabled: Bool = false

    static func click() {
        guard !isDisabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func buy() {
        guard !isDisabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    static func sell() {
        guard !isDisabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func celebrate() {
        guard !isDisabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
