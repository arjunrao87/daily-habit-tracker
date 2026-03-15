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
                VStack(alignment: .leading, spacing: 20) {
                    Text(viewModel.todayDisplayDate)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(HabitType.allCases, id: \.self) { habit in
                            HabitCardView(
                                habitType: habit,
                                count: viewModel.count(for: habit)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Today's Habits")
            .task {
                await viewModel.loadTodayLogs()
            }
        }
    }
}
