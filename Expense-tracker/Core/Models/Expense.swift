import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID

    var createdAt: Date
    var occurredAt: Date

    var kindRaw: String
    var approvalRaw: String

    var amount: Decimal
    var currencyCode: String

    var title: String
    var notes: String?

    var category: String
    var paymentMethod: String

    var emotionalTagRaw: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        occurredAt: Date = .now,
        kind: TransactionKind = .expense,
        approvalStatus: ExpenseApprovalStatus = .pending,
        amount: Decimal,
        currencyCode: String,
        title: String,
        notes: String? = nil,
        category: String,
        paymentMethod: String,
        emotionalTag: EmotionalTag = .none
    ) {
        self.id = id
        self.createdAt = createdAt
        self.occurredAt = occurredAt
        self.kindRaw = kind.rawValue
        self.approvalRaw = approvalStatus.rawValue
        self.amount = amount
        self.currencyCode = currencyCode
        self.title = title
        self.notes = notes
        self.category = category
        self.paymentMethod = paymentMethod
        self.emotionalTagRaw = emotionalTag.rawValue
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    var approvalStatus: ExpenseApprovalStatus {
        get { ExpenseApprovalStatus(rawValue: approvalRaw) ?? .pending }
        set { approvalRaw = newValue.rawValue }
    }

    var emotionalTag: EmotionalTag {
        get { EmotionalTag(rawValue: emotionalTagRaw) ?? .none }
        set { emotionalTagRaw = newValue.rawValue }
    }
}
