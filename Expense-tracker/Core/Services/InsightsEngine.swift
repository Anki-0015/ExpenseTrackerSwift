import Foundation
import SwiftData

struct Insight: Identifiable, Equatable {
    let id: UUID
    let title: String
    let detail: String

    init(title: String, detail: String) {
        self.id = UUID()
        self.title = title
        self.detail = detail
    }
}

/// Explainable, rule-based insights.
struct InsightsEngine {
    func generate(monthKey: Date, modelContext: ModelContext, currencyCode: String) -> [Insight] {
        var insights: [Insight] = []

        let calendar = Calendar.current
        guard let end = calendar.date(byAdding: .month, value: 1, to: monthKey) else { return [] }

        let expenses = fetchApprovedExpenses(modelContext: modelContext, from: monthKey, to: end, currencyCode: currencyCode)
        if expenses.isEmpty {
            return [Insight(title: "Start logging daily", detail: "Add at least one expense per day to unlock meaningful insights.")]
        }

        insights.append(contentsOf: moodCorrelation(expenses: expenses))
        insights.append(contentsOf: categoryBreadthInsight(expenses: expenses))
        insights.append(contentsOf: volatilityChangeInsight(modelContext: modelContext, monthKey: monthKey, currencyCode: currencyCode))

        return insights
    }

    private func fetchApprovedExpenses(modelContext: ModelContext, from: Date, to: Date, currencyCode: String) -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { exp in
                exp.currencyCode == currencyCode && exp.occurredAt >= from && exp.occurredAt < to
            }
        )

        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        let approvedRaw = ExpenseApprovalStatus.approved.rawValue
        return fetched.filter { $0.kindRaw == TransactionKind.expense.rawValue && $0.approvalRaw == approvedRaw }
    }

    private func moodCorrelation(expenses: [Expense]) -> [Insight] {
        let stressed = expenses.filter { $0.emotionalTag == .stressed }
        guard stressed.count >= 3 else { return [] }

        let foodKeywords = ["Food", "Dining", "Snacks"]
        let stressedFood = stressed.filter { foodKeywords.contains($0.category) }.reduce(0.0) { $0 + (NSDecimalNumber(decimal: $1.amount).doubleValue) }
        let allFood = expenses.filter { foodKeywords.contains($0.category) }.reduce(0.0) { $0 + (NSDecimalNumber(decimal: $1.amount).doubleValue) }

        if allFood > 0, (stressedFood / allFood) > 0.55 {
            return [Insight(title: "Stress spending increases food expenses", detail: "More than half of your Food spending happened on days marked as Stressed.")]
        }

        return []
    }

    private func categoryBreadthInsight(expenses: [Expense]) -> [Insight] {
        let categories = Set(expenses.map { $0.category })
        if categories.count <= 4 {
            return [Insight(title: "You save better in months with fewer categories", detail: "This month your spending is concentrated across \(categories.count) categories—this often correlates with higher savings.")]
        }
        if categories.count >= 10 {
            return [Insight(title: "Spending is fragmented", detail: "You used \(categories.count) categories this month. Consider consolidating categories to spot patterns faster.")]
        }
        return []
    }

    private func volatilityChangeInsight(modelContext: ModelContext, monthKey: Date, currencyCode: String) -> [Insight] {
        let calendar = Calendar.current
        guard let prev = calendar.date(byAdding: .month, value: -1, to: monthKey),
              let endPrev = calendar.date(byAdding: .month, value: 1, to: prev),
              let endCurrent = calendar.date(byAdding: .month, value: 1, to: monthKey) else { return [] }

        let prevExpenses = fetchApprovedExpenses(modelContext: modelContext, from: prev, to: endPrev, currencyCode: currencyCode)
        let currExpenses = fetchApprovedExpenses(modelContext: modelContext, from: monthKey, to: endCurrent, currencyCode: currencyCode)

        guard prevExpenses.count >= 10, currExpenses.count >= 10 else { return [] }

        let prevCv = dailyCv(expenses: prevExpenses)
        let currCv = dailyCv(expenses: currExpenses)

        guard prevCv > 0 else { return [] }

        let change = (currCv - prevCv) / prevCv
        if change >= 0.18 {
            let pct = Int(round(change * 100))
            return [Insight(title: "Your spending volatility increased \(pct)%", detail: "Your day-to-day spending swings are larger than last month. Try setting smaller daily caps.")]
        }

        return []
    }

    private func dailyCv(expenses: [Expense]) -> Double {
        var daily: [Date: Double] = [:]
        for exp in expenses {
            let day = Calendar.current.startOfDay(for: exp.occurredAt)
            daily[day, default: 0] += (exp.amount as NSDecimalNumber).doubleValue
        }
        let totals = daily.values
        guard totals.count >= 2 else { return 0 }
        let mean = totals.reduce(0, +) / Double(totals.count)
        guard mean > 0 else { return 0 }
        let variance = totals.reduce(0) { $0 + pow($1 - mean, 2) } / Double(totals.count)
        return sqrt(variance) / mean
    }
}
