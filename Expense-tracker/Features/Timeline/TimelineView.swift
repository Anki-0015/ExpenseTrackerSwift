import SwiftUI
import SwiftData

struct TimelineItem: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case expense
        case income
        case goal
        case budget
    }

    let id: UUID
    let kind: Kind
    let date: Date
    let title: String
    let subtitle: String
    let amount: Decimal?
    let currencyCode: String?
}

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Expense.occurredAt, order: .reverse) private var expenses: [Expense]
    @Query(sort: \SavingsGoal.createdAt, order: .reverse) private var goals: [SavingsGoal]
    @Query(sort: \Budget.monthKey, order: .reverse) private var budgets: [Budget]
    @Query(sort: \BudgetChangeEvent.changedAt, order: .reverse) private var budgetChanges: [BudgetChangeEvent]
    @Query(sort: \GoalAllocationEvent.createdAt, order: .reverse) private var goalAllocations: [GoalAllocationEvent]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items) { item in
                        GlassCard {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: icon(for: item.kind))
                                    .font(.title3)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let amount = item.amount, let code = item.currencyCode {
                                    Text(Formatters.currency(amount: amount, currencyCode: code))
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Timeline")
        }
    }

    private var items: [TimelineItem] {
        var all: [TimelineItem] = []

        for exp in expenses where exp.approvalStatus != .discarded {
            all.append(
                TimelineItem(
                    id: exp.id,
                    kind: exp.kind == .income ? .income : .expense,
                    date: exp.occurredAt,
                    title: exp.title.isEmpty ? exp.category : exp.title,
                    subtitle: "\(exp.category) • \(Formatters.compactDate(exp.occurredAt))",
                    amount: exp.amount,
                    currencyCode: exp.currencyCode
                )
            )
        }

        for g in goals {
            all.append(
                TimelineItem(
                    id: g.id,
                    kind: .goal,
                    date: g.createdAt,
                    title: "Goal: \(g.name)",
                    subtitle: g.deadline.map { "Deadline \(Formatters.compactDate($0))" } ?? "No deadline",
                    amount: nil,
                    currencyCode: nil
                )
            )
        }

        for b in budgets {
            all.append(
                TimelineItem(
                    id: b.id,
                    kind: .budget,
                    date: b.monthKey,
                    title: "Budget set",
                    subtitle: Formatters.compactDate(b.monthKey),
                    amount: nil,
                    currencyCode: nil
                )
            )
        }

        for change in budgetChanges.prefix(50) {
            all.append(
                TimelineItem(
                    id: change.id,
                    kind: .budget,
                    date: change.changedAt,
                    title: "Budget change",
                    subtitle: change.summary,
                    amount: nil,
                    currencyCode: nil
                )
            )
        }

        for alloc in goalAllocations.prefix(50) {
            all.append(
                TimelineItem(
                    id: alloc.id,
                    kind: .goal,
                    date: alloc.createdAt,
                    title: "Saved to \(alloc.goalName)",
                    subtitle: Formatters.compactDate(alloc.createdAt),
                    amount: alloc.amount,
                    currencyCode: alloc.currencyCode
                )
            )
        }

        return all.sorted(by: { $0.date > $1.date })
    }

    private func icon(for kind: TimelineItem.Kind) -> String {
        switch kind {
        case .expense: return "arrow.down.circle"
        case .income: return "arrow.up.circle"
        case .goal: return "target"
        case .budget: return "tray.full"
        }
    }
}

#Preview {
    let container = PersistenceController.makeModelContainer(inMemory: true)
    return TimelineView()
        .environment(AppState())
        .modelContainer(container)
}
