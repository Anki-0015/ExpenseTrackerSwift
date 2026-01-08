import Foundation
import SwiftData

@Model
final class GoalAllocationEvent {
    @Attribute(.unique) var id: UUID

    var goalId: UUID
    var goalName: String

    var amount: Decimal
    var currencyCode: String

    var createdAt: Date

    init(
        id: UUID = UUID(),
        goalId: UUID,
        goalName: String,
        amount: Decimal,
        currencyCode: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.goalId = goalId
        self.goalName = goalName
        self.amount = amount
        self.currencyCode = currencyCode
        self.createdAt = createdAt
    }
}
