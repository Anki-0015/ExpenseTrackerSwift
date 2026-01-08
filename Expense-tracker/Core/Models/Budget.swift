import Foundation
import SwiftData

@Model
final class Budget {
    @Attribute(.unique) var id: UUID

    /// Month bucket key (first day of month at 00:00 in user's calendar)
    var monthKey: Date

    /// Total income assigned for zero-based budgeting
    var assignedIncome: Decimal

    /// Planned budgets per category
    var categoryBudgetsData: Data

    /// Per-category carry-forward destinations
    var carryRulesData: Data

    init(
        id: UUID = UUID(),
        monthKey: Date,
        assignedIncome: Decimal = 0,
        categoryBudgets: [String: Decimal] = [:],
        carryRules: [String: CarryForwardDestination] = [:]
    ) {
        self.id = id
        self.monthKey = monthKey
        self.assignedIncome = assignedIncome
        self.categoryBudgetsData = (try? JSONEncoder().encode(categoryBudgets.mapValues { NSDecimalNumber(decimal: $0).stringValue })) ?? Data()
        self.carryRulesData = (try? JSONEncoder().encode(carryRules.mapValues { $0.rawValue })) ?? Data()
    }

    var categoryBudgets: [String: Decimal] {
        get {
            guard let raw = try? JSONDecoder().decode([String: String].self, from: categoryBudgetsData) else { return [:] }
            return raw.compactMapValues { Decimal(string: $0) }
        }
        set {
            let encoded = newValue.mapValues { NSDecimalNumber(decimal: $0).stringValue }
            categoryBudgetsData = (try? JSONEncoder().encode(encoded)) ?? Data()
        }
    }

    var carryRules: [String: CarryForwardDestination] {
        get {
            guard let raw = try? JSONDecoder().decode([String: String].self, from: carryRulesData) else { return [:] }
            return raw.compactMapValues { CarryForwardDestination(rawValue: $0) }
        }
        set {
            carryRulesData = (try? JSONEncoder().encode(newValue.mapValues { $0.rawValue })) ?? Data()
        }
    }
}
