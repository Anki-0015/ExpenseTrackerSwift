import Foundation
import SwiftData

@Model
final class CarryForwardEvent {
    /// Unique, deterministic id to keep carry-forward idempotent.
    @Attribute(.unique) var id: String

    var fromMonthKey: Date
    var toMonthKey: Date
    var category: String
    var destinationRaw: String
    var amount: Decimal
    var appliedAt: Date

    init(
        id: String,
        fromMonthKey: Date,
        toMonthKey: Date,
        category: String,
        destination: CarryForwardDestination,
        amount: Decimal,
        appliedAt: Date = .now
    ) {
        self.id = id
        self.fromMonthKey = fromMonthKey
        self.toMonthKey = toMonthKey
        self.category = category
        self.destinationRaw = destination.rawValue
        self.amount = amount
        self.appliedAt = appliedAt
    }

    var destination: CarryForwardDestination {
        get { CarryForwardDestination(rawValue: destinationRaw) ?? .nextMonth }
        set { destinationRaw = newValue.rawValue }
    }
}
