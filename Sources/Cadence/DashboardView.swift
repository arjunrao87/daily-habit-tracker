import SwiftUI

struct DashboardView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: DashboardViewModel
    @State private var historyHabit: Habit?
    @State private var showAddHabit = false
    private let networkMonitor: NetworkMonitor

    init(habitRepository: HabitRepository, logRepository: HabitLogRepository, networkMonitor: NetworkMonitor) {
        self._viewModel = State(initialValue: DashboardViewModel(
            habitRepository: habitRepository, logRepository: logRepository
        ))
        self.networkMonitor = networkMonitor
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !networkMonitor.isConnected {
                        HStack(spacing: 8) {
                            Image(systemName: "wifi.slash")
                                .font(.caption)
                            Text("You're offline — habits will sync when you reconnect")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.yellow.opacity(0.12))
                        }
                        .padding(.horizontal)
                    }

                    Text(viewModel.todayDisplayDate)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    streakBanner

                    if viewModel.habits.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.habits) { habit in
                                HabitCardView(
                                    habit: habit,
                                    count: viewModel.count(for: habit),
                                    streak: viewModel.streak(for: habit),
                                    onTap: {
                                        Task {
                                            await viewModel.incrementCount(for: habit)
                                        }
                                    },
                                    onDecrement: {
                                        Task {
                                            await viewModel.decrementCount(for: habit)
                                        }
                                    },
                                    onReset: {
                                        Task {
                                            await viewModel.resetCount(for: habit)
                                        }
                                    },
                                    onHistory: {
                                        historyHabit = habit
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteHabit(habit)
                                        }
                                    }
                                )
                            }

                            addHabitCard
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(viewModel.greeting)
            .refreshable {
                await viewModel.loadAll()
            }
            .task {
                await viewModel.loadAll()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await viewModel.reloadIfDayChanged()
                    }
                }
            }
            .sheet(item: $historyHabit) { habit in
                HabitHistoryView(
                    habit: habit,
                    dateCounts: viewModel.dateCounts(for: habit),
                    streak: viewModel.streak(for: habit)
                )
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView { name, icon, color, isInverse in
                    Task {
                        await viewModel.createHabit(
                            name: name, icon: icon, color: color, isInverse: isInverse
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var streakBanner: some View {
        if viewModel.isPerfectDay {
            let streak = viewModel.perfectDayStreak
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("All habits hit — \(streak) day streak!")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.orange.opacity(0.12).gradient)
            }
            .padding(.horizontal)
        } else if let best = viewModel.bestStreakHabit {
            HStack(spacing: 8) {
                Image(systemName: best.habit.icon)
                    .foregroundStyle(best.habit.swiftUIColor)
                Text("\(best.habit.name) — \(best.streak) day streak")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.secondary.opacity(0.08))
            }
            .padding(.horizontal)
        }
    }

    private var addHabitCard: some View {
        Button {
            showAddHabit = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("Add Habit")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No habits yet")
                .font(.title3.weight(.medium))
            Text("Tap the button below to add your first habit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showAddHabit = true
            } label: {
                Text("Add Habit")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
