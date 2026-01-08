import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Budget.monthKey, order: .reverse) private var budgets: [Budget]
    @Query(sort: \Expense.occurredAt, order: .reverse) private var expenses: [Expense]

    @State private var selectedDate: Date = .now
    @State private var presentingEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    monthPicker

                    if let budget = currentBudget {
                        budgetSummary(budget)
                        categoryBreakdown(budget)
                    } else {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No budget for this month")
                                    .font(.headline)
                                Text("Set category budgets and carry-forward rules.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentingEditor = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $presentingEditor) {
                BudgetEditorView(monthKey: monthKey)
            }
        }
    }

    private var monthPicker: some View {
        GlassCard {
            HStack {
                Text("Month")
                    .font(.headline)
                Spacer()
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .labelsHidden()
            }
        }
    }

    private var monthKey: Date {
        DateBuckets.monthKey(for: selectedDate, fiscalStartDay: appState.settings.fiscalMonthStartDay)
    }

    private var currentBudget: Budget? {
        budgets.first(where: { $0.monthKey == monthKey })
    }

    private func budgetSummary(_ budget: Budget) -> some View {
        let currency = appState.settings.defaultCurrencyCode
        let planned = budget.categoryBudgets.values.reduce(Decimal(0), +)
        let spent = approvedExpensesForMonth.reduce(Decimal(0)) { $0 + $1.amount }

        let unassigned: Decimal = {
            guard appState.settings.zeroBasedBudgetEnabled else { return 0 }
            return max(0, budget.assignedIncome - planned)
        }()

        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.currency(amount: planned, currencyCode: currency))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.currency(amount: spent, currencyCode: currency))
                            .font(.headline)
                    }
                }

                if appState.settings.zeroBasedBudgetEnabled {
                    HStack {
                        Text("Unassigned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.currency(amount: unassigned, currencyCode: currency))
                            .font(.caption.weight(.semibold))
                    }
                    ProgressView(value: unassignedAmountProgress(unassigned: unassigned, income: budget.assignedIncome))
                }
            }
        }
    }

    private func categoryBreakdown(_ budget: Budget) -> some View {
        let currency = appState.settings.defaultCurrencyCode
        let categories = budget.categoryBudgets.keys.sorted()

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Categories")
                    .font(.headline)

                if categories.isEmpty {
                    Text("Add categories in the editor.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(categories, id: \.self) { cat in
                        let planned = budget.categoryBudgets[cat] ?? 0
                        let spent = approvedExpensesForMonth
                            .filter { $0.category == cat }
                            .reduce(Decimal(0)) { $0 + $1.amount }
                        let ratio = planned == 0 ? 0 : min(1.0, (NSDecimalNumber(decimal: spent).doubleValue) / max(1, NSDecimalNumber(decimal: planned).doubleValue))

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(cat)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(Formatters.currency(amount: spent, currencyCode: currency)) / \(Formatters.currency(amount: planned, currencyCode: currency))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: ratio)
                                .tint(ratio > 1.0 ? Color.red : Color.accentColor)

                            if let rule = budget.carryRules[cat] {
                                Text("Carry: \(rule.rawValue)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Long-press insights") { }
                        }
                    }
                }
            }
        }
    }

    private var approvedExpensesForMonth: [Expense] {
        let cal = Calendar.current
        guard let end = cal.date(byAdding: .month, value: 1, to: monthKey) else { return [] }
        return expenses.filter {
            $0.kind == .expense && $0.approvalStatus == .approved && $0.currencyCode == appState.settings.defaultCurrencyCode && $0.occurredAt >= monthKey && $0.occurredAt < end
        }
    }

    private func unassignedAmountProgress(unassigned: Decimal, income: Decimal) -> Double {
        let inc = max(0.0, NSDecimalNumber(decimal: income).doubleValue)
        guard inc > 0 else { return 0 }
        let un = max(0.0, NSDecimalNumber(decimal: unassigned).doubleValue)
        return min(1.0, un / inc)
    }
}

struct BudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let monthKey: Date

    @Query(sort: \Budget.monthKey, order: .reverse) private var budgets: [Budget]

    @State private var assignedIncomeText: String = ""

    @State private var rows: [Row] = []

    struct Row: Identifiable, Equatable {
        let id: UUID
        var category: String
        var amountText: String
        var carry: CarryForwardDestination
    }

    var body: some View {
        NavigationStack {
            Form {
                if appState.settings.zeroBasedBudgetEnabled {
                    Section("Zero-based") {
                        TextField("Assigned income", text: $assignedIncomeText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Categories") {
                    ForEach($rows) { $row in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Category", text: $row.category)
                            TextField("Budget", text: $row.amountText)
                                .keyboardType(.decimalPad)
                            Picker("Carry-forward", selection: $row.carry) {
                                ForEach(CarryForwardDestination.allCases) { d in
                                    Text(d.rawValue).tag(d)
                                }
                            }
                        }
                    }
                    .onDelete { idx in rows.remove(atOffsets: idx) }

                    Button("Add category") {
                        rows.append(Row(id: UUID(), category: "", amountText: "", carry: .nextMonth))
                    }
                }
            }
            .navigationTitle("Budget Editor")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() } }
            }
            .onAppear {
                load()
            }
        }
    }

    private var existing: Budget? {
        budgets.first(where: { $0.monthKey == monthKey })
    }

    private func load() {
        if let b = existing {
            if appState.settings.zeroBasedBudgetEnabled {
                assignedIncomeText = NSDecimalNumber(decimal: b.assignedIncome).stringValue
            }

            let carry = b.carryRules
            rows = b.categoryBudgets.map { key, value in
                Row(
                    id: UUID(),
                    category: key,
                    amountText: NSDecimalNumber(decimal: value).stringValue,
                    carry: carry[key] ?? .nextMonth
                )
            }
            .sorted(by: { $0.category < $1.category })
        } else {
            rows = [Row(id: UUID(), category: "Food", amountText: "8000", carry: .nextMonth)]
        }
    }

    private func save() {
        let income = Decimal(string: assignedIncomeText.replacingOccurrences(of: ",", with: ".")) ?? 0
        var categoryBudgets: [String: Decimal] = [:]
        var carryRules: [String: CarryForwardDestination] = [:]

        for row in rows {
            let cat = row.category.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cat.isEmpty else { continue }
            let amount = Decimal(string: row.amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
            categoryBudgets[cat] = amount
            carryRules[cat] = row.carry
        }

        if let b = existing {
            let beforeBudgets = b.categoryBudgets
            let beforeCarry = b.carryRules
            let beforeIncome = b.assignedIncome

            b.assignedIncome = income
            b.categoryBudgets = categoryBudgets
            b.carryRules = carryRules

            if beforeBudgets != categoryBudgets || beforeCarry != carryRules || beforeIncome != income {
                let summary = "Updated budget: \(categoryBudgets.count) categories"
                modelContext.insert(BudgetChangeEvent(monthKey: monthKey, summary: summary))
            }
        } else {
            let b = Budget(monthKey: monthKey, assignedIncome: income, categoryBudgets: categoryBudgets, carryRules: carryRules)
            modelContext.insert(b)
            modelContext.insert(BudgetChangeEvent(monthKey: monthKey, summary: "Created budget"))
        }

        dismiss()
    }
}
