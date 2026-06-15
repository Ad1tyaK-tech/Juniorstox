import SwiftUI

/// Wraps any card content and reveals a colored action background when dragged horizontally.
/// isLeading: true  → drag RIGHT reveals action on the left  (buy)
/// isLeading: false → drag LEFT  reveals action on the right (sell)
struct SwipeRevealCard<Content: View>: View {

    let actionColor: Color
    let actionIcon: String
    let actionLabel: String
    let isLeading: Bool
    let onAction: () -> Void
    let content: Content

    init(
        actionColor: Color,
        actionIcon: String,
        actionLabel: String,
        isLeading: Bool,
        onAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.actionColor = actionColor
        self.actionIcon = actionIcon
        self.actionLabel = actionLabel
        self.isLeading = isLeading
        self.onAction = onAction
        self.content = content()
    }

    @State private var dragOffset: CGFloat = 0

    private let threshold: CGFloat  = 70
    private let maxReveal: CGFloat  = 84

    private var revealWidth: CGFloat { isLeading ? max(0, dragOffset) : max(0, -dragOffset) }
    private var progress: CGFloat   { min(revealWidth / threshold, 1.0) }

    var body: some View {
        ZStack(alignment: isLeading ? .leading : .trailing) {
            // Action background — grows as the card slides
            HStack(spacing: 0) {
                if !isLeading { Spacer(minLength: 0) }

                ZStack {
                    actionColor
                    VStack(spacing: 5) {
                        Image(systemName: actionIcon)
                            .font(.title3.bold())
                        Text(actionLabel)
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .scaleEffect(0.5 + 0.5 * progress)
                    .opacity(Double(progress))
                }
                .frame(width: revealWidth)

                if isLeading { Spacer(minLength: 0) }
            }

            // Card content — shifts horizontally on drag
            content
                .offset(x: dragOffset)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .gesture(
            DragGesture(minimumDistance: 15, coordinateSpace: .local)
                .onChanged { value in
                    let w = value.translation.width
                    let h = value.translation.height
                    // Only respond to predominantly horizontal drags so vertical
                    // ScrollView scrolling is not interrupted.
                    guard abs(w) > abs(h) else { return }

                    if isLeading {
                        guard w > 0 else { return }
                        dragOffset = w < maxReveal ? w : maxReveal + (w - maxReveal) * 0.12
                    } else {
                        guard w < 0 else { return }
                        let raw = -w
                        dragOffset = -(raw < maxReveal ? raw : maxReveal + (raw - maxReveal) * 0.12)
                    }
                }
                .onEnded { value in
                    let w = value.translation.width
                    let triggered = isLeading ? w >= threshold : w <= -threshold
                    if triggered {
                        // Snap fully open, then snap back and fire action
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                            dragOffset = isLeading ? maxReveal : -maxReveal
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                            onAction()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}
