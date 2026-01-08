import Foundation
import SwiftData

enum SampleData {
    static func seedIfNeeded(modelContext: ModelContext, settings: AppSettings) {
        // Only seed if no expenses exist.
        let descriptor = FetchDescriptor<Expense>()
        let existing = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let currency = settings.defaultCurrencyCode

        let templates: [ExpenseTemplate] = [
            ExpenseTemplate(name: "Coffee", amount: 150, category: "Food", paymentMethod: "Card"),
            ExpenseTemplate(name: "Cab", amount: 300, category: "Transport", paymentMethod: "Card"),
            ExpenseTemplate(name: "Groceries", amount: 1200, category: "Food", paymentMethod: "Card"),
        ]
        templates.forEach { modelContext.insert($0) }

        let now = Date()
        let e1 = Expense(amount: 150, currencyCode: currency, title: "Coffee", category: "Food", paymentMethod: "Card", emotionalTag: .neutral)
        e1.occurredAt = Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now
        e1.approvalStatus = .approved

        let e2 = Expense(amount: 320, currencyCode: currency, title: "Cab", category: "Transport", paymentMethod: "Card", emotionalTag: .stressed)
        e2.occurredAt = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        e2.approvalStatus = .approved

        let e3 = Expense(amount: 800, currencyCode: currency, title: "Dinner", category: "Food", paymentMethod: "Card", emotionalTag: .happy)
        e3.occurredAt = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
        e3.approvalStatus = .pending

        [e1, e2, e3].forEach { modelContext.insert($0) }

        let monthKey = DateBuckets.monthKey(for: now)
        let budget = Budget(
            monthKey: monthKey,
            assignedIncome: 50000,
            categoryBudgets: ["Food": 8000, "Transport": 4000, "Bills": 12000, "Fun": 3000],
            carryRules: ["Food": .nextMonth, "Transport": .nextMonth, "Fun": .savings]
        )
        modelContext.insert(budget)

        let goal = SavingsGoal(name: "Emergency Fund", targetAmount: 100000, currentAmount: 25000, deadline: Calendar.current.date(byAdding: .month, value: 10, to: now))
        modelContext.insert(goal)
    }
}
