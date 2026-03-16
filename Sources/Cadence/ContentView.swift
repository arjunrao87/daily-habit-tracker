import SwiftUI

/// Root view of the app. Shows a launch screen while authenticating,
/// then transitions to the habit dashboard. Supports light and dark mode.
struct ContentView: View {
    @State private var isReady = false
    @State private var authError: (any Error)?
    private let launcher: AppLauncher
    private let networkMonitor: NetworkMonitor

    init(launcher: AppLauncher = AppLauncher(), networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.launcher = launcher
        self.networkMonitor = networkMonitor
    }

    var body: some View {
        Group {
            if isReady {
                DashboardView(
                    habitRepository: launcher.habitRepository,
                    logRepository: launcher.logRepository,
                    networkMonitor: networkMonitor
                )
                .transition(.opacity)
            } else {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isReady)
        .overlay(alignment: .top) {
            if isReady, authError != nil, networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Couldn't connect")
                        .font(.caption.weight(.medium))
                    Spacer()
                    Button("Retry") {
                        Task {
                            authError = nil
                            do {
                                _ = try await launcher.launch()
                            } catch {
                                authError = error
                            }
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.orange.opacity(0.12))
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task {
            networkMonitor.start()
            do {
                _ = try await launcher.launch()
            } catch {
                authError = error
            }
            isReady = true
        }
    }
}
