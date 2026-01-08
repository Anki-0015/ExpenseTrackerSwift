import Foundation
import SwiftData

@Model
final class FinancialScore {
    @Attribute(.unique) var monthKey: Date
    var score: Int
    var breakdownData: Data

    init(month: Date, score: Int, breakdown: [String: Int]) {
        self.monthKey = month
        self.score = max(0, min(100, score))
        self.breakdownData = (try? JSONEncoder().encode(breakdown)) ?? Data()
    }

    var breakdown: [String: Int] {
        get { (try? JSONDecoder().decode([String: Int].self, from: breakdownData)) ?? [:] }
        set { breakdownData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
