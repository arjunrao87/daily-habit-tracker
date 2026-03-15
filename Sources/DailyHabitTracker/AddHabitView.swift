import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss

    var onCreate: (String, String, String, Bool) -> Void

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "blue"
    @State private var isInverse = false

    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    private var resolvedColor: Color {
        switch selectedColor {
        case "blue": .blue
        case "purple": .purple
        case "green": .green
        case "orange": .orange
        case "red": .red
        case "pink": .pink
        case "teal": .teal
        case "indigo": .indigo
        default: .blue
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Habit name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: iconColumns, spacing: 12) {
                        ForEach(Habit.availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedIcon == icon ? resolvedColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedIcon == icon ? resolvedColor : .clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: colorColumns, spacing: 12) {
                        ForEach(Habit.availableColors, id: \.self) { color in
                            let resolved = colorFor(color)
                            Circle()
                                .fill(resolved.gradient)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                        .padding(2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(resolved, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Inverse habit", isOn: $isInverse)
                } footer: {
                    Text("Inverse habits track days without activity (e.g. days without junk food).")
                }

                // Preview
                Section("Preview") {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.9))
                            Text(name.isEmpty ? "Habit" : name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("0")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 16)
                        .frame(width: 150, height: 140)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(resolvedColor.gradient)
                        )
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onCreate(name, selectedIcon, selectedColor, isInverse)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": .blue
        case "purple": .purple
        case "green": .green
        case "orange": .orange
        case "red": .red
        case "pink": .pink
        case "teal": .teal
        case "indigo": .indigo
        default: .blue
        }
    }
}
