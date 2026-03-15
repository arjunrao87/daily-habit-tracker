import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(repository: HabitLogRepository) {
        self._viewModel = State(initialValue: DashboardViewModel(repository: repository))
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(viewModel.todayDisplayDate)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(HabitType.allCases, id: \.self) { habit in
                            HabitCardView(
                                habitType: habit,
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
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Today's Habits")
            .refreshable {
                await viewModel.loadTodayLogs()
            }
            .task {
                await viewModel.loadTodayLogs()
            }
        }
    }
}
