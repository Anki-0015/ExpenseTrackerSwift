import Foundation
import SwiftData

struct FinancialHealthScoreResult: Equatable {
    var score: Int
    var breakdown: [String: Int]
}

/// 0–100 monthly score derived from local data only.
struct FinancialHealthScoring {
    func score(monthKey: Date, modelContext: ModelContext, settings: AppSettings) -> FinancialHealthScoreResult {
        let monthStart = monthKey
        let calendar = Calendar.current
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return FinancialHealthScoreResult(score: 0, breakdown: [:])
        }

        let expenses = fetchExpenses(modelContext: modelContext, from: monthStart, to: monthEnd, kind: .expense, currencyCode: settings.defaultCurrencyCode)
        let income = fetchExpenses(modelContext: modelContext, from: monthStart, to: monthEnd, kind: .income, currencyCode: settings.defaultCurrencyCode)

        let totalExpenses = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let totalIncome = income.reduce(Decimal(0)) { $0 + $1.amount }

        let budget = fetchBudget(modelContext: modelContext, monthKey: monthKey)
        let budgetAdherence = budgetAdherenceScore(expenses: expenses, budget: budget)
        let consistency = consistencyScore(expenses: expenses, monthStart: monthStart, monthEnd: monthEnd)
        let savingsRatio = savingsRatioScore(totalIncome: totalIncome, totalExpenses: totalExpenses)
        let volatility = volatilityScore(expenses: expenses)

        // Weighted blend. Keep simple and explainable.
        let weighted = Int(round(
            0.35 * Double(budgetAdherence)
            + 0.25 * Double(consistency)
            + 0.25 * Double(savingsRatio)
            + 0.15 * Double(volatility)
        ))

        return FinancialHealthScoreResult(
            score: max(0, min(100, weighted)),
            breakdown: [
                "Budget adherence": budgetAdherence,
                "Consistency": consistency,
                "Savings ratio": savingsRatio,
                "Volatility": volatility,
            ]
        )
    }

    private func fetchExpenses(modelContext: ModelContext, from: Date, to: Date, kind: TransactionKind, currencyCode: String) -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { exp in
                exp.currencyCode == currencyCode && exp.occurredAt >= from && exp.occurredAt < to
            },
            sortBy: [SortDescriptor(\Expense.occurredAt, order: .forward)]
        )

        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        let kindRaw = kind.rawValue
        let approvedRaw = ExpenseApprovalStatus.approved.rawValue
        return fetched.filter { $0.kindRaw == kindRaw && $0.approvalRaw == approvedRaw }
    }

    private func fetchBudget(modelContext: ModelContext, monthKey: Date) -> Budget? {
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { b in b.monthKey == monthKey }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func budgetAdherenceScore(expenses: [Expense], budget: Budget?) -> Int {
        guard let budget else { return 60 } // neutral baseline if no budget set
        let planned = budget.categoryBudgets
        if planned.isEmpty { return 60 }

        var plannedTotal = Decimal(0)
        var actualTotal = Decimal(0)

        for (category, plannedAmount) in planned {
            plannedTotal += plannedAmount
            let actual = expenses.filter { $0.category == category }.reduce(Decimal(0)) { $0 + $1.amount }
            actualTotal += actual
        }

        guard plannedTotal > 0 else { return 60 }

        let ratio = (NSDecimalNumber(decimal: actualTotal).doubleValue) / max(1, NSDecimalNumber(decimal: plannedTotal).doubleValue)
        // 1.0 == perfect; penalize over-spend more than under-spend.
        let overspendPenalty = max(0, ratio - 1.0) * 60
        let underspendPenalty = max(0, 1.0 - ratio) * 20
        let score = 100 - Int(round(overspendPenalty + underspendPenalty))
        return max(0, min(100, score))
    }

    private func consistencyScore(expenses: [Expense], monthStart: Date, monthEnd: Date) -> Int {
        let days = max(1, Calendar.current.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 30)
        let distinctDays = Set(expenses.map { Calendar.current.startOfDay(for: $0.occurredAt) }).count
        let ratio = Double(distinctDays) / Double(days)
        // Encourage daily logging: 0.6+ is strong.
        let score = Int(round(min(1.0, ratio / 0.6) * 100))
        return max(0, min(100, score))
    }

    private func savingsRatioScore(totalIncome: Decimal, totalExpenses: Decimal) -> Int {
        let income = max(0.0, NSDecimalNumber(decimal: totalIncome).doubleValue)
        let expenses = max(0.0, NSDecimalNumber(decimal: totalExpenses).doubleValue)
        guard income > 0 else { return 40 }
        let savings = max(0.0, income - expenses)
        let ratio = savings / income
        // 20% savings is a solid target.
        let score = Int(round(min(1.0, ratio / 0.2) * 100))
        return max(0, min(100, score))
    }

    private func volatilityScore(expenses: [Expense]) -> Int {
        // Spending volatility based on daily totals stddev/mean.
        var daily: [Date: Double] = [:]
        for exp in expenses {
            let day = Calendar.current.startOfDay(for: exp.occurredAt)
            daily[day, default: 0] += (exp.amount as NSDecimalNumber).doubleValue
        }
        let totals = daily.values
        guard totals.count >= 5 else { return 70 }

        let mean = totals.reduce(0, +) / Double(totals.count)
        guard mean > 0 else { return 70 }

        let variance = totals.reduce(0) { partial, x in
            partial + pow(x - mean, 2)
        } / Double(totals.count)

        let std = sqrt(variance)
        let cv = std / mean // coefficient of variation

        // Lower volatility -> higher score. cv 0.3 is good, 1.0 is bad.
        let normalized = 1.0 - min(1.0, max(0.0, (cv - 0.3) / 0.7))
        let score = Int(round(normalized * 100))
        return max(0, min(100, score))
    }
}
