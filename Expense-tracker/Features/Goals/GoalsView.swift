import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \SavingsGoal.createdAt, order: .reverse) private var goals: [SavingsGoal]

    @State private var presentingNew = false

    var body: some View {
        NavigationStack {
            List {
                if goals.isEmpty {
                    Text("Create a goal like Trip or Emergency Fund.")
                        .foregroundStyle(.secondary)
                }

                ForEach(goals) { goal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(goal.name)
                                .font(.headline)
                            Spacer()
                            Text("\(Int(round(goal.progress * 100)))%")
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: goal.progress)

                        HStack {
                            Text("\(Formatters.currency(amount: goal.currentAmount, currencyCode: appState.settings.defaultCurrencyCode)) of \(Formatters.currency(amount: goal.targetAmount, currencyCode: appState.settings.defaultCurrencyCode))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let deadline = goal.deadline {
                                Text("By \(Formatters.compactDate(deadline))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Swipe to allocate savings (manual)
                        Text("Swipe to allocate")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("+500") { allocate(goal, amount: 500) }
                        Button("+1000") { allocate(goal, amount: 1000) }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $presentingNew) {
                NewGoalView()
            }
        }
    }

    private func allocate(_ goal: SavingsGoal, amount: Decimal) {
        goal.currentAmount += amount

        let event = GoalAllocationEvent(
            goalId: goal.id,
            goalName: goal.name,
            amount: amount,
            currencyCode: appState.settings.defaultCurrencyCode
        )
        modelContext.insert(event)
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            modelContext.delete(goals[idx])
        }
    }
}

struct NewGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var targetText: String = ""
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $name)
                    TextField("Target amount", text: $targetText)
                        .keyboardType(.decimalPad)

                    Toggle("Deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("", selection: $deadline, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { create() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Decimal(string: targetText.replacingOccurrences(of: ",", with: ".")) == nil)
                }
            }
        }
    }

    private func create() {
        guard let target = Decimal(string: targetText.replacingOccurrences(of: ",", with: ".")) else { return }
        let goal = SavingsGoal(name: name, targetAmount: target, deadline: hasDeadline ? deadline : nil)
        modelContext.insert(goal)
        dismiss()
    }
}
