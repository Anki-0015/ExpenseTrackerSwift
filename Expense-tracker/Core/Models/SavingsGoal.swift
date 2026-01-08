import Foundation
import SwiftData

@Model
final class SavingsGoal {
    @Attribute(.unique) var id: UUID

    var name: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var deadline: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        deadline: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.createdAt = createdAt
    }

    var progress: Double {
        guard targetAmount != 0 else { return 0 }
        let current = (currentAmount as NSDecimalNumber).doubleValue
        let target = (targetAmount as NSDecimalNumber).doubleValue
        return max(0, min(1, current / target))
    }
}
