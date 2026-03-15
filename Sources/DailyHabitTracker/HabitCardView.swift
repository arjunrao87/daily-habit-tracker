import SwiftUI

struct HabitCardView: View {
    let habitType: HabitType
    let count: Int
    var onTap: (() -> Void)?

    @State private var isPressed = false

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
        .sensoryFeedback(.impact(flexibility: .solid), trigger: count)
    }
}
