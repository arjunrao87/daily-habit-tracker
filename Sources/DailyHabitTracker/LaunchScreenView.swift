import SwiftUI

/// A launch screen displayed while the app authenticates.
/// Adapts to both light and dark mode using system colors.
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)

                Text("Daily Habits")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)

                ProgressView()
                    .padding(.top, 8)
            }
        }
    }
}
