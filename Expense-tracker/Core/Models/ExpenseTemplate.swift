import Foundation
import SwiftData

@Model
final class ExpenseTemplate {
    @Attribute(.unique) var id: UUID

    var name: String
    var amount: Decimal
    var category: String
    var paymentMethod: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        category: String,
        paymentMethod: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.paymentMethod = paymentMethod
        self.createdAt = createdAt
    }
}
