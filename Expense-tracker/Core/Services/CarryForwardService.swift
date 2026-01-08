import Foundation
import SwiftData

struct CarryForwardService {
    /// Applies carry-forward from the previous month into the provided month.
    /// Safe to call repeatedly (idempotent via `CarryForwardEvent`).
    func applyCarryForward(into currentMonthKey: Date, modelContext: ModelContext, settings: AppSettings) {
        let calendar = Calendar.current
        guard let fromMonthKey = calendar.date(byAdding: .month, value: -1, to: currentMonthKey) else { return }

        guard let fromBudget = fetchBudget(modelContext: modelContext, monthKey: fromMonthKey) else { return }

        let currency = settings.defaultCurrencyCode
        let actuals = actualSpentByCategory(modelContext: modelContext, monthKey: fromMonthKey, currencyCode: currency)

        for (category, planned) in fromBudget.categoryBudgets {
            let spent = actuals[category] ?? 0
            let unused = planned - spent
            guard unused > 0 else { continue }

            let destination = fromBudget.carryRules[category] ?? .nextMonth
            guard destination != .none else { continue }

            let eventId = makeEventId(from: fromMonthKey, to: currentMonthKey, category: category, destination: destination)
            if carryEventExists(modelContext: modelContext, id: eventId) {
                continue
            }

            switch destination {
            case .nextMonth:
                applyToNextMonthBudget(
                    modelContext: modelContext,
                    toMonthKey: currentMonthKey,
                    category: category,
                    amount: unused
                )

            case .savings:
                applyToCarryForwardSavingsGoal(
                    modelContext: modelContext,
                    amount: unused,
                    settings: settings
                )

            case .none:
                break
            }

            let event = CarryForwardEvent(
                id: eventId,
                fromMonthKey: fromMonthKey,
                toMonthKey: currentMonthKey,
                category: category,
                destination: destination,
                amount: unused
            )
            modelContext.insert(event)
        }
    }

    private func fetchBudget(modelContext: ModelContext, monthKey: Date) -> Budget? {
        let descriptor = FetchDescriptor<Budget>(predicate: #Predicate<Budget> { b in b.monthKey == monthKey })
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func actualSpentByCategory(modelContext: ModelContext, monthKey: Date, currencyCode: String) -> [String: Decimal] {
        let calendar = Calendar.current
        guard let end = calendar.date(byAdding: .month, value: 1, to: monthKey) else { return [:] }

        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { exp in
                exp.currencyCode == currencyCode && exp.occurredAt >= monthKey && exp.occurredAt < end
            }
        )

        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        let approvedRaw = ExpenseApprovalStatus.approved.rawValue
        let expenses = fetched.filter { $0.kindRaw == TransactionKind.expense.rawValue && $0.approvalRaw == approvedRaw }
        var totals: [String: Decimal] = [:]
        for e in expenses {
            totals[e.category, default: 0] += e.amount
        }
        return totals
    }

    private func applyToNextMonthBudget(modelContext: ModelContext, toMonthKey: Date, category: String, amount: Decimal) {
        let existing = fetchBudget(modelContext: modelContext, monthKey: toMonthKey)
        if let b = existing {
            var map = b.categoryBudgets
            map[category, default: 0] += amount
            b.categoryBudgets = map
        } else {
            let b = Budget(monthKey: toMonthKey, assignedIncome: 0, categoryBudgets: [category: amount], carryRules: [:])
            modelContext.insert(b)
        }
    }

    private func applyToCarryForwardSavingsGoal(modelContext: ModelContext, amount: Decimal, settings: AppSettings) {
        if let goalId = settings.carryForwardSavingsGoalId {
            let descriptor = FetchDescriptor<SavingsGoal>(predicate: #Predicate<SavingsGoal> { g in g.id == goalId })
            if let goal = (try? modelContext.fetch(descriptor))?.first {
                goal.currentAmount += amount
                return
            }
        }

        let descriptor = FetchDescriptor<SavingsGoal>(predicate: #Predicate<SavingsGoal> { g in g.name == "Carry-forward Savings" })
        if let goal = (try? modelContext.fetch(descriptor))?.first {
            goal.currentAmount += amount
        } else {
            let goal = SavingsGoal(name: "Carry-forward Savings", targetAmount: 0, currentAmount: amount, deadline: nil)
            modelContext.insert(goal)
        }
    }

    private func carryEventExists(modelContext: ModelContext, id: String) -> Bool {
        let descriptor = FetchDescriptor<CarryForwardEvent>(predicate: #Predicate<CarryForwardEvent> { e in e.id == id })
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    private func makeEventId(from: Date, to: Date, category: String, destination: CarryForwardDestination) -> String {
        let fromKey = isoMonth(from)
        let toKey = isoMonth(to)
        let cat = category.lowercased().replacingOccurrences(of: " ", with: "-")
        return "cf_\(fromKey)_\(toKey)_\(cat)_\(destination.rawValue)"
    }

    private func isoMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = .init(identifier: .gregorian)
        f.locale = .init(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f.string(from: date)
    }
}
