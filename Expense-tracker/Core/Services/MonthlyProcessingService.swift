import Foundation
import SwiftData

struct MonthlyProcessingService {
    func upsertFinancialScore(monthKey: Date, modelContext: ModelContext, settings: AppSettings) {
        let scoring = FinancialHealthScoring()
        let result = scoring.score(monthKey: monthKey, modelContext: modelContext, settings: settings)

        let descriptor = FetchDescriptor<FinancialScore>(predicate: #Predicate<FinancialScore> { s in s.monthKey == monthKey })
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            existing.score = result.score
            existing.breakdown = result.breakdown
        } else {
            let score = FinancialScore(month: monthKey, score: result.score, breakdown: result.breakdown)
            modelContext.insert(score)
        }
    }
}
