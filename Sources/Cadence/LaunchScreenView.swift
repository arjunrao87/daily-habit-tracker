import SwiftUI

/// A launch screen displayed while the app authenticates.
/// Adapts to both light and dark mode using system colors.
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            #if os(iOS)
            Color(.systemBackground)
                .ignoresSafeArea()
            #else
            Color(.windowBackgroundColor)
                .ignoresSafeArea()
            #endif

            VStack(spacing: 16) {
                Text("🎯")
                    .font(.system(size: 64))

                Text("Cadence")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)

                ProgressView()
                    .padding(.top, 8)
            }
        }
    }
}
