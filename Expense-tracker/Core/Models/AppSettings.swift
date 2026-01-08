import Foundation

struct AppSettings: Codable, Equatable {
    var defaultCurrencyCode: String
    var fiscalMonthStartDay: Int
    var zeroBasedBudgetEnabled: Bool
    var reviewReminderEnabled: Bool
    var reviewReminderTime: DateComponents
    var appLockEnabled: Bool
    var carryForwardSavingsGoalId: UUID?

    static let `default` = AppSettings(
        defaultCurrencyCode: Locale.current.currency?.identifier ?? "INR",
        fiscalMonthStartDay: 1,
        zeroBasedBudgetEnabled: false,
        reviewReminderEnabled: true,
        reviewReminderTime: DateComponents(hour: 21, minute: 0),
        appLockEnabled: false,
        carryForwardSavingsGoalId: nil
    )
}
