import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Expense.occurredAt, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \ExpenseTemplate.createdAt, order: .reverse) private var templates: [ExpenseTemplate]

    @State private var presentingAdd = false
    @State private var isRefreshing = false

    private var monthKey: Date { DateBuckets.monthKey(for: .now, fiscalStartDay: appState.settings.fiscalMonthStartDay) }
    private var monthRange: (start: Date, end: Date) {
        DateBuckets.monthRange(for: .now, fiscalStartDay: appState.settings.fiscalMonthStartDay)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Financial Health Score
                    scoreCard
                    
                    // Key Stats
                    statsGrid
                    
                    // Category Breakdown Chart
                    categoryChart
                    
                    // Spending Trend
                    trendChart
                    
                    // Templates
                    if !templates.isEmpty {
                        templatesSection
                    }
                    
                    // Pending Review
                    pendingCard
                    
                    // Insights
                    insightsCard
                    
                    // Recent Transactions
                    recentList
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .refreshable {
                await refresh()
            }
            .navigationTitle("Dashboard")
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
    
    // MARK: - Score Card
    private var scoreCard: some View {
        let score = currentScore
        
        return GlassCard {
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Financial Health")
                        .font(Typography.captionLarge)
                        .foregroundStyle(ColorTokens.textSecondary)
                    
                    Text("\(score)")
                        .font(Typography.displaySmall)
                        .foregroundStyle(ColorTokens.primary)
                    
                    Text(healthMessage(for: score))
                        .font(Typography.captionMedium)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
                
                Spacer()
                
                ScoreRingView(score: score)
                    .frame(width: 90, height: 90)
            }
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        let currency = appState.settings.defaultCurrencyCode
        let monthExpenses = approvedExpensesForMonth
        let total = monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let avgPerDay = averagePerDay(monthExpenses)
        let streak = loggingStreakDays(expenses: monthExpenses)
        let count = monthExpenses.count
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            StatCard(
                title: "Total Spent",
                value: Formatters.currency(amount: total, currencyCode: currency),
                subtitle: "This month",
                icon: "creditcard.fill",
                iconColor: ColorTokens.error
            )
            
            StatCard(
                title: "Avg Per Day",
                value: Formatters.currency(amount: avgPerDay, currencyCode: currency),
                subtitle: "Daily average",
                icon: "calendar.badge.clock",
                iconColor: ColorTokens.info
            )
            
            StatCard(
                title: "Transactions",
                value: "\(count)",
                subtitle: "\(streak) day streak",
                icon: "list.bullet.rectangle.fill",
                iconColor: ColorTokens.success
            )
            
            StatCard(
                title: "Logging",
                value: "\(Int(dailyLoggingRatio * 100))%",
                subtitle: "Days tracked",
                icon: "checkmark.seal.fill",
                iconColor: ColorTokens.warning
            )
        }
    }
    
    // MARK: - Category Chart
    private var categoryChart: some View {
        let expenses = approvedExpensesForMonth
        let categoryTotals = Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { expenses in
                expenses.reduce(Decimal(0)) { $0 + $1.amount }
            }
            .sorted { $0.value > $1.value }
        
        let chartData = categoryTotals.enumerated().map { index, item in
            CategoryPieChart.CategoryData(
                category: item.key,
                amount: item.value,
                color: ColorTokens.colorForCategory(item.key)
            )
        }
        
        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Category Breakdown")
                        .font(Typography.headlineSmall)
                    
                    Spacer()
                    
                    Text(Formatters.compactDate(monthKey))
                        .font(Typography.captionMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                
                if chartData.isEmpty {
                    EmptyStateView(
                        icon: "chart.pie.fill",
                        title: "No Categories Yet",
                        subtitle: "Add expenses to see category breakdown"
                    )
                    .frame(height: 200)
                } else {
                    CategoryPieChart(data: chartData, showLegend: true)
                }
            }
        }
    }
    
    // MARK: - Trend Chart
    private var trendChart: some View {
        let calendar = Calendar.current
        let expenses = approvedExpensesForMonth
        
        // Group by day
        let dailyTotals = Dictionary(grouping: expenses, by: { calendar.startOfDay(for: $0.occurredAt) })
            .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amount } }
            .sorted { $0.key < $1.key }
        
        let chartData = dailyTotals.map { date, amount in
            TrendLineChart.DataPoint(date: date, amount: amount)
        }
        
        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Spending Trend")
                        .font(Typography.headlineSmall)
                    
                    Spacer()
                    
                    Text("Last 30 days")
                        .font(Typography.captionMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                
                if chartData.isEmpty {
                    EmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "No Spending Data",
                        subtitle: "Track expenses to see trends"
                    )
                    .frame(height: 180)
                } else {
                    TrendLineChart(data: chartData, lineColor: ColorTokens.primary, chartHeight: 180)
                }
            }
        }
    }
    
    // MARK: - Templates Section
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Add")
                .font(Typography.headlineSmall)
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.xs)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(templates) { template in
                        Button {
                            addFromTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .font(.caption)
                                        .foregroundStyle(ColorTokens.warning)
                                    
                                    Spacer()
                                }
                                
                                Text(template.name)
                                    .font(Typography.titleSmall)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                    .lineLimit(1)
                                
                                Text(Formatters.currency(amount: template.amount, currencyCode: appState.settings.defaultCurrencyCode))
                                    .font(Typography.bodyMedium)
                                    .foregroundStyle(ColorTokens.success)
                                
                                Text(template.category)
                                    .font(Typography.captionSmall)
                                    .foregroundStyle(ColorTokens.textTertiary)
                            }
                            .padding(Spacing.md)
                            .frame(width: 140)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                                    .fill(ColorTokens.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                                    .strokeBorder(ColorTokens.borderLight, lineWidth: Spacing.borderThin)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Pending Card
    private var pendingCard: some View {
        let pending = allExpenses.filter { $0.approvalStatus == .pending && $0.kind == .expense }
        
        return GlassCard {
            HStack(spacing: Spacing.md) {
                Image(systemName: "clock.badge.fill")
                    .font(.title2)
                    .foregroundStyle(ColorTokens.warning)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Pending Review")
                        .font(Typography.titleMedium)
                        .foregroundStyle(ColorTokens.textPrimary)
                    
                    Text("\(pending.count) \(pending.count == 1 ? "transaction" : "transactions")")
                        .font(Typography.captionMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                
                Spacer()
                
                NavigationLink(destination: ReviewView()) {
                    Text("Review")
                        .font(Typography.titleSmall)
                        .foregroundStyle(ColorTokens.primary)
                }
            }
        }
    }

    // MARK: - Insights Card
    private var insightsCard: some View {
        let engine = InsightsEngine()
        let insights = engine.generate(monthKey: monthKey, modelContext: modelContext, currencyCode: appState.settings.defaultCurrencyCode)

        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(ColorTokens.info)
                    
                    Text("Insights")
                        .font(Typography.headlineSmall)
                    
                    Spacer()
                }
                
                if insights.isEmpty {
                    Text("Keep logging expenses to unlock personalized insights.")
                        .font(Typography.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ForEach(insights.prefix(3)) { insight in
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(insight.title)
                                    .font(Typography.titleSmall)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                
                                Text(insight.detail)
                                    .font(Typography.captionLarge)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                                    .fill(ColorTokens.infoLight)
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent List
    private var recentList: some View {
        let recent = allExpenses.filter { $0.kind == .expense && $0.approvalStatus != .discarded }.prefix(10)

        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Recent Transactions")
                        .font(Typography.headlineSmall)
                    
                    Spacer()
                    
                    NavigationLink(destination: TimelineView()) {
                        Text("See All")
                            .font(Typography.captionLarge)
                            .foregroundStyle(ColorTokens.primary)
                    }
                }

                if recent.isEmpty {
                    EmptyStateView(
                        icon: "tray.fill",
                        title: "No Expenses Yet",
                        subtitle: "Tap + to add your first expense",
                        actionTitle: "Add Expense",
                        action: { presentingAdd = true }
                    )
                    .frame(height: 200)
                } else {
                    VStack(spacing: Spacing.sm) {
                        ForEach(Array(recent)) { exp in
                            expenseRow(exp)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func expenseRow(_ exp: Expense) -> some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(ColorTokens.colorForCategory(exp.category).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconForCategory(exp.category))
                        .font(.system(size: 18))
                        .foregroundStyle(ColorTokens.colorForCategory(exp.category))
                )
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(exp.title.isEmpty ? exp.category : exp.title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                Text("\(exp.category) • \(Formatters.compactTime(exp.occurredAt))")
                    .font(Typography.captionMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(Formatters.currency(amount: exp.amount, currencyCode: exp.currencyCode))
                    .font(Typography.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                if exp.approvalStatus == .pending {
                    Text("Pending")
                        .font(Typography.captionSmall)
                        .foregroundStyle(ColorTokens.warning)
                }
            }
        }
        .padding(Spacing.sm)
        .contentShape(Rectangle())
        .contextMenu {
            Button(exp.approvalStatus == .approved ? "Mark Pending" : "Approve") {
                exp.approvalStatus = exp.approvalStatus == .approved ? .pending : .approved
            }
            Button("Discard", role: .destructive) {
                exp.approvalStatus = .discarded
            }
        }
    }
    
    // MARK: - Helper Functions
    private func healthMessage(for score: Int) -> String {
        switch score {
        case 80...100: return "Excellent financial health!"
        case 60..<80: return "Good financial management"
        case 40..<60: return "Room for improvement"
        default: return "Consider budget adjustments"
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        let lowercased = category.lowercased()
        if lowercased.contains("food") || lowercased.contains("dining") {
            return "fork.knife"
        } else if lowercased.contains("transport") || lowercased.contains("car") {
            return "car.fill"
        } else if lowercased.contains("shop") || lowercased.contains("retail") {
            return "bag.fill"
        } else if lowercased.contains("bill") || lowercased.contains("utilities") {
            return "doc.text.fill"
        } else if lowercased.contains("health") || lowercased.contains("medical") {
            return "cross.fill"
        } else if lowercased.contains("entertainment") {
            return "tv.fill"
        } else {
            return "dollarsign.circle.fill"
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
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    @MainActor
    private func refresh() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        isRefreshing = false
    }
}

#Preview {
    let container = PersistenceController.makeModelContainer(inMemory: true)
    return DashboardView()
        .environment(AppState())
        .modelContainer(container)
}
