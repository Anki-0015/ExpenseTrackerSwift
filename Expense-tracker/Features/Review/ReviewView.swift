import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Expense.occurredAt, order: .reverse) private var expenses: [Expense]

    var body: some View {
        NavigationStack {
            List {
                Section("Pending") {
                    let pending = expenses.filter { $0.kind == .expense && $0.approvalStatus == .pending }
                    if pending.isEmpty {
                        Text("Nothing pending. You're up to date.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pending) { exp in
                            row(exp)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button("Approve") {
                                        exp.approvalStatus = .approved
                                    }
                                    .tint(.green)

                                    Button("Discard", role: .destructive) {
                                        exp.approvalStatus = .discarded
                                    }
                                }
                        }
                    }
                }

                Section("Recently approved") {
                    let approved = expenses.filter { $0.kind == .expense && $0.approvalStatus == .approved }.prefix(15)
                    if approved.isEmpty {
                        Text("No approved expenses yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(approved)) { exp in
                            row(exp)
                        }
                    }
                }
            }
            .navigationTitle("Review")
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Approve all") {
                        approveAllPending()
                    }
                    .disabled(expenses.allSatisfy { $0.approvalStatus != .pending || $0.kind != .expense })
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ exp: Expense) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exp.title.isEmpty ? exp.category : exp.title)
                    .font(.subheadline.weight(.semibold))
                Text("\(exp.category) • \(Formatters.compactDate(exp.occurredAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Formatters.currency(amount: exp.amount, currencyCode: exp.currencyCode))
                .font(.subheadline.weight(.semibold))
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Approve") { exp.approvalStatus = .approved }
            Button("Discard", role: .destructive) { exp.approvalStatus = .discarded }
        }
    }

    private func approveAllPending() {
        for exp in expenses where exp.kind == .expense && exp.approvalStatus == .pending {
            exp.approvalStatus = .approved
        }
    }
}

#Preview {
    let container = PersistenceController.makeModelContainer(inMemory: true)
    return ReviewView()
        .environment(AppState())
        .modelContainer(container)
}
