import Foundation

enum ExpenseApprovalStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case approved
    case discarded

    var id: String { rawValue }
}

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }
}

enum EmotionalTag: String, Codable, CaseIterable, Identifiable {
    case none
    case neutral
    case stressed
    case happy

    var id: String { rawValue }
}

enum CarryForwardDestination: String, Codable, CaseIterable, Identifiable {
    case nextMonth
    case savings
    case none

    var id: String { rawValue }
}

enum TimeBucket: String, Codable, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening
    case night

    var id: String { rawValue }

    static func from(date: Date, calendar: Calendar = .current) -> TimeBucket {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .night
        }
    }
}
