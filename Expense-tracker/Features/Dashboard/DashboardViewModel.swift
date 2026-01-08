import Foundation
import Observation
import SwiftData

@Observable
final class DashboardViewModel {
    private let scoring = FinancialHealthScoring()
    private let insights = InsightsEngine()

    func score(monthKey: Date, modelContext: ModelContext, settings: AppSettings) -> FinancialHealthScoreResult {
        scoring.score(monthKey: monthKey, modelContext: modelContext, settings: settings)
    }

    func insights(monthKey: Date, modelContext: ModelContext, currencyCode: String) -> [Insight] {
        insights.generate(monthKey: monthKey, modelContext: modelContext, currencyCode: currencyCode)
    }
}
