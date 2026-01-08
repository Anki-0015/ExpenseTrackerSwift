import Foundation
import SwiftData

@Model
final class BudgetChangeEvent {
    @Attribute(.unique) var id: UUID

    var monthKey: Date
    var changedAt: Date
    var summary: String

    init(id: UUID = UUID(), monthKey: Date, changedAt: Date = .now, summary: String) {
        self.id = id
        self.monthKey = monthKey
        self.changedAt = changedAt
        self.summary = summary
    }
}
