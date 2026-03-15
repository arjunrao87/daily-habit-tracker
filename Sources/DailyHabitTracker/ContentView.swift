import SwiftUI

/// Root view of the app. Shows a launch screen while authenticating,
/// then transitions to the habit dashboard. Supports light and dark mode.
struct ContentView: View {
    @State private var isReady = false
    private let launcher: AppLauncher

    init(launcher: AppLauncher = AppLauncher()) {
        self.launcher = launcher
    }

    var body: some View {
        Group {
            if isReady {
                DashboardView(habitRepository: launcher.habitRepository, logRepository: launcher.logRepository)
                    .transition(.opacity)
            } else {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isReady)
        .task {
            do {
                _ = try await launcher.launch()
            } catch {
                // Show dashboard even if auth fails — offline-friendly
            }
            isReady = true
        }
    }
}
