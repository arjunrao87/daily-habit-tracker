import SwiftUI

struct HabitHistoryView: View {
    let habit: Habit
    let dateCounts: [String: Int]
    let streak: Int

    @Environment(\.dismiss) private var dismiss

    private let weeksToShow = 16
    private let dayLabels = ["M", "", "W", "", "F", "", "S"]

    private var color: Color { habit.swiftUIColor }

    private var weeks: [[Date?]] {
        let calendar = Calendar(identifier: .iso8601)
        let today = calendar.startOfDay(for: Date())

        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let currentWeekMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }
        guard let startMonday = calendar.date(byAdding: .weekOfYear, value: -(weeksToShow - 1), to: currentWeekMonday) else {
            return []
        }

        var result: [[Date?]] = []
        var weekStart = startMonday

        for _ in 0..<weeksToShow {
            var week: [Date?] = []
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    week.append(nil)
                    continue
                }
                if date > today {
                    week.append(nil)
                } else {
                    week.append(date)
                }
            }
            result.append(week)
            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }

        return result
    }

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func countFor(_ date: Date?) -> Int {
        guard let date else { return 0 }
        let key = formatter.string(from: date)
        return dateCounts[key] ?? 0
    }

    private func cellColor(_ date: Date?) -> Color {
        guard let date else {
            #if os(iOS)
            return Color(.systemBackground)
            #else
            return Color(.windowBackgroundColor)
            #endif
        }
        let count = countFor(date)
        if habit.isInverse {
            return count == 0 ? color.opacity(0.8) : color.opacity(0.15)
        } else {
            if count == 0 { return color.opacity(0.1) }
            let clamped = min(count, 5)
            let opacity = 0.2 + (Double(clamped) / 5.0) * 0.7
            return color.opacity(opacity)
        }
    }

    private var monthLabels: [(String, Int)] {
        let calendar = Calendar(identifier: .iso8601)
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        var labels: [(String, Int)] = []
        var lastMonth = -1

        for (weekIndex, week) in weeks.enumerated() {
            if let monday = week.first ?? nil {
                let month = calendar.component(.month, from: monday)
                if month != lastMonth {
                    labels.append((monthFormatter.string(from: monday), weekIndex))
                    lastMonth = month
                }
            }
        }
        return labels
    }

    private var totalDays: Int {
        weeks.flatMap { $0 }.compactMap { $0 }.count
    }

    private var activeDays: Int {
        weeks.flatMap { $0 }.compactMap { $0 }.filter { countFor($0) > 0 }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 24) {
                        statBox(value: "\(streak)", label: habit.isInverse ? "days clean" : "day streak")
                        statBox(value: "\(activeDays)", label: "active days")
                        statBox(
                            value: totalDays > 0 ? "\(Int(Double(activeDays) / Double(totalDays) * 100))%" : "0%",
                            label: "consistency"
                        )
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 0) {
                            Text("")
                                .frame(width: 16)

                            GeometryReader { geo in
                                let cellSize = (geo.size.width - CGFloat(weeksToShow - 1) * 3) / CGFloat(weeksToShow)

                                ForEach(Array(monthLabels.enumerated()), id: \.offset) { _, item in
                                    let (label, weekIndex) = item
                                    Text(label)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .position(
                                            x: CGFloat(weekIndex) * (cellSize + 3) + cellSize / 2,
                                            y: 6
                                        )
                                }
                            }
                            .frame(height: 14)
                        }

                        HStack(alignment: .top, spacing: 0) {
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    Text(dayLabels[dayIndex])
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 16, height: 14)
                                }
                            }

                            HStack(spacing: 3) {
                                ForEach(0..<weeks.count, id: \.self) { weekIndex in
                                    VStack(spacing: 3) {
                                        ForEach(0..<7, id: \.self) { dayIndex in
                                            let date = weeks[weekIndex][dayIndex]
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(cellColor(date))
                                                .aspectRatio(1, contentMode: .fit)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 4) {
                        Spacer()
                        Text(habit.isInverse ? "did it" : "less")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(0..<5, id: \.self) { level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color.opacity(habit.isInverse
                                    ? (level == 0 ? 0.8 : 0.15)
                                    : 0.1 + Double(level) / 4.0 * 0.8
                                ))
                                .frame(width: 12, height: 12)
                        }
                        Text(habit.isInverse ? "clean" : "more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(habit.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
