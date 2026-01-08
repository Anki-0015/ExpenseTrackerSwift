import Foundation
import SwiftData

enum PersistenceController {
    static func makeModelContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            Expense.self,
            SavingsGoal.self,
            FinancialScore.self,
            Budget.self,
            ExpenseTemplate.self,
            CarryForwardEvent.self,
            BudgetChangeEvent.self,
            GoalAllocationEvent.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
