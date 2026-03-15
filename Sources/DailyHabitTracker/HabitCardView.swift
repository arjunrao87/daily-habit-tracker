import SwiftUI

struct HabitCardView: View {
    let habitType: HabitType
    let count: Int
    var streak: Int = 0
    var onTap: (() -> Void)?
    var onDecrement: (() -> Void)?
    var onReset: (() -> Void)?

    @State private var isPressed = false

    private var streakLabel: String {
        if habitType.isInverse {
            return streak == 1 ? "1 day clean" : "\(streak) days clean"
        } else {
            return "\(streak)-day streak"
        }
    }

    private var displayName: String {
        switch habitType {
        case .reading: "Reading"
        case .meditation: "Meditation"
        case .gym: "Gym"
        case .cholesterol: "Cholesterol"
        }
    }

    private var cardColor: Color {
        switch habitType {
        case .reading: .blue
        case .meditation: .purple
        case .gym: .green
        case .cholesterol: .orange
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(displayName)
                .font(.headline)
                .foregroundStyle(.white)

            Text("\(count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            if streak > 0 {
                Text(streakLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(cardColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
        .onTapGesture {
            isPressed = true
            onTap?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }
        .contextMenu {
            Button {
                onDecrement?()
            } label: {
                Label("Decrement (−1)", systemImage: "minus.circle")
            }
            .disabled(count <= 0)

            Button(role: .destructive) {
                onReset?()
            } label: {
                Label("Reset to 0", systemImage: "arrow.counterclockwise")
            }
            .disabled(count <= 0)
        }
        .sensoryFeedback(.impact(flexibility: .solid), trigger: count)
    }
}
