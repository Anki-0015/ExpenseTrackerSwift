import Foundation

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

struct AppSettings: Codable, Equatable {
    var defaultCurrencyCode: String
    var fiscalMonthStartDay: Int
    var zeroBasedBudgetEnabled: Bool
    var reviewReminderEnabled: Bool
    var reviewReminderTime: DateComponents
    var appLockEnabled: Bool
    var carryForwardSavingsGoalId: UUID?
    var appearance: AppAppearance

    static let `default` = AppSettings(
        defaultCurrencyCode: Locale.current.currency?.identifier ?? "INR",
        fiscalMonthStartDay: 1,
        zeroBasedBudgetEnabled: false,
        reviewReminderEnabled: true,
        reviewReminderTime: DateComponents(hour: 21, minute: 0),
        appLockEnabled: false,
        carryForwardSavingsGoalId: nil,
        appearance: .system
    )
}
