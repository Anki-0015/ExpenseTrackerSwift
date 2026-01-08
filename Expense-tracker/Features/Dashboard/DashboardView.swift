import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Expense.occurredAt, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \ExpenseTemplate.createdAt, order: .reverse) private var templates: [ExpenseTemplate]

    @State private var presentingAdd = false

    private var monthKey: Date { DateBuckets.monthKey(for: .now, fiscalStartDay: appState.settings.fiscalMonthStartDay) }
    private var monthRange: (start: Date, end: Date) {
        DateBuckets.monthRange(for: .now, fiscalStartDay: appState.settings.fiscalMonthStartDay)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    topRow

                    quickStats

                    templatesRow

                    pendingCard

                    insightsCard

                    recentList
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Expense OS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Add expense")
                }
            }
            .sheet(isPresented: $presentingAdd) {
                AddExpenseView()
            }
        }
    }

    private var topRow: some View {
        HStack(alignment: .center, spacing: 12) {
            let score = currentScore
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.compactDate(monthKey))
                            .font(.headline)
                    }
                    Spacer()
                    ScoreRingView(score: score)
                        .frame(width: 70, height: 70)
                }
            }
        }
    }

    private var quickStats: some View {
        let currency = appState.settings.defaultCurrencyCode
        let monthExpenses = approvedExpensesForMonth
        let total = monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let avgPerDay = averagePerDay(monthExpenses)
        let streak = loggingStreakDays(expenses: monthExpenses)

        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.currency(amount: total, currencyCode: currency))
                            .font(.title3.weight(.semibold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Avg/day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.currency(amount: avgPerDay, currencyCode: currency))
                            .font(.headline)
                    }
                }

                ProgressView(value: dailyLoggingRatio)
                    .tint(.accentColor)

                HStack {
                    Text("Daily logging")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Streak: \(streak)d")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var templatesRow: some View {
        Group {
            if templates.isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(templates) { t in
                            Button {
                                addFromTemplate(t)
                            } label: {
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(t.name)
                                            .font(.headline)
                                        Text(Formatters.currency(amount: t.amount, currencyCode: appState.settings.defaultCurrencyCode))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 150, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var pendingCard: some View {
        let pending = allExpenses.filter { $0.approvalStatus == .pending && $0.kind == .expense }
        return GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pending review")
                        .font(.headline)
                    Text("\(pending.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                NavigationLink("Review", destination: ReviewView())
                    .font(.headline)
            }
        }
    }

    private var insightsCard: some View {
        let engine = InsightsEngine()
        let insights = engine.generate(monthKey: monthKey, modelContext: modelContext, currencyCode: appState.settings.defaultCurrencyCode)

        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Insights")
                    .font(.headline)
                if insights.isEmpty {
                    Text("Keep logging to unlock insights.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(insights.prefix(3)) { insight in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.title)
                                .font(.subheadline.weight(.semibold))
                            Text(insight.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var recentList: some View {
        let recent = allExpenses.filter { $0.kind == .expense && $0.approvalStatus != .discarded }.prefix(10)

        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent")
                    .font(.headline)

                if recent.isEmpty {
                    Text("No expenses yet. Add your first one.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(recent)) { exp in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exp.title.isEmpty ? exp.category : exp.title)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(exp.category) • \(Formatters.compactTime(exp.occurredAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Formatters.currency(amount: exp.amount, currencyCode: exp.currencyCode))
                                .font(.subheadline.weight(.semibold))
                        }
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button(exp.approvalStatus == .approved ? "Mark pending" : "Approve") {
                                exp.approvalStatus = exp.approvalStatus == .approved ? .pending : .approved
                            }
                            Button("Discard", role: .destructive) {
                                exp.approvalStatus = .discarded
                            }
                        }
                    }
                }
            }
        }
    }

    private var approvedExpensesForMonth: [Expense] {
        return allExpenses.filter {
            $0.kind == .expense && $0.approvalStatus == .approved && $0.currencyCode == appState.settings.defaultCurrencyCode && $0.occurredAt >= monthKey && $0.occurredAt < end
        }
    }

    private var end: Date { monthRange.end }

    private var dailyLoggingRatio: Double {
        let cal = Calendar.current
        let days = max(1, cal.dateComponents([.day], from: monthRange.start, to: monthRange.end).day ?? 30)
        let distinctDays = Set(approvedExpensesForMonth.map { cal.startOfDay(for: $0.occurredAt) }).count
        return min(1.0, Double(distinctDays) / Double(days))
    }

    private func averagePerDay(_ expenses: [Expense]) -> Decimal {
        let cal = Calendar.current
        let days = max(1, cal.dateComponents([.day], from: monthRange.start, to: monthRange.end).day ?? 30)
        let total = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        return total / Decimal(days)
    }

    private var currentScore: Int {
        let scoring = FinancialHealthScoring()
        let result = scoring.score(monthKey: monthKey, modelContext: modelContext, settings: appState.settings)
        return result.score
    }

    private func loggingStreakDays(expenses: [Expense]) -> Int {
        let calendar = Calendar.current
        let byDay = Set(expenses.map { calendar.startOfDay(for: $0.occurredAt) })
        guard !byDay.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: Date())

        while byDay.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        return streak
    }

    private func addFromTemplate(_ template: ExpenseTemplate) {
        let exp = Expense(
            amount: template.amount,
            currencyCode: appState.settings.defaultCurrencyCode,
            title: template.name,
            category: template.category,
            paymentMethod: template.paymentMethod
        )
        exp.approvalStatus = .pending
        modelContext.insert(exp)
    }
}

#Preview {
    let container = PersistenceController.makeModelContainer(inMemory: true)
    return DashboardView()
        .environment(AppState())
        .modelContainer(container)
}
