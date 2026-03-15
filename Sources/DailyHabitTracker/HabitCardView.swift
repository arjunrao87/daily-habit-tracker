import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let count: Int
    var streak: Int = 0
    var onTap: (() -> Void)?
    var onDecrement: (() -> Void)?
    var onReset: (() -> Void)?
    var onHistory: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    private var streakLabel: String {
        if habit.isInverse {
            return streak == 1 ? "1 day clean" : "\(streak) days clean"
        } else {
            return "\(streak)-day streak"
        }
    }

    private var cardColor: Color { habit.swiftUIColor }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: habit.icon)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))

            Text(habit.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text("\(count)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            if streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                    Text(streakLabel)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.85))
                .contentTransition(.numericText())
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor.gradient)
                .shadow(
                    color: cardColor.opacity(colorScheme == .dark ? 0.3 : 0.25),
                    radius: 8, y: 4
                )
        }
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
                onHistory?()
            } label: {
                Label("View History", systemImage: "calendar")
            }

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

            Divider()

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete Habit", systemImage: "trash")
            }
        }
        .sensoryFeedback(.impact(flexibility: .solid), trigger: count)
    }
}
