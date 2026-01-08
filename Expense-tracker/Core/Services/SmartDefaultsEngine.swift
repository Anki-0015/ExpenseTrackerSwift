import Foundation
import SwiftData

struct SmartDefaultsSuggestion: Equatable {
    var category: String
    var paymentMethod: String
}

/// Rule-based smart defaults derived from local history.
struct SmartDefaultsEngine {
    struct Input: Equatable {
        var amount: Decimal
        var occurredAt: Date
    }

    func suggest(input: Input, modelContext: ModelContext, currencyCode: String) -> SmartDefaultsSuggestion {
        // Heuristics:
        // 1) Find most recent expense within amount band AND same time bucket.
        // 2) Otherwise fall back to most common category for amount band.
        // 3) Payment method: most common for chosen category.

        let bucket = TimeBucket.from(date: input.occurredAt)
        let amountBand = amountRange(for: input.amount)

        let recentSameBucket = fetchRecentExpenses(
            modelContext: modelContext,
            kind: .expense,
            currencyCode: currencyCode,
            dateAfter: Calendar.current.date(byAdding: .day, value: -45, to: input.occurredAt) ?? .distantPast
        )

        if let match = recentSameBucket.first(where: { amountBand.contains($0.amount) && TimeBucket.from(date: $0.occurredAt) == bucket }) {
            return SmartDefaultsSuggestion(
                category: match.category,
                paymentMethod: mostCommonPaymentMethod(for: match.category, in: recentSameBucket) ?? match.paymentMethod
            )
        }

        if let category = mostCommonCategory(in: recentSameBucket, where: { amountBand.contains($0.amount) }) {
            return SmartDefaultsSuggestion(
                category: category,
                paymentMethod: mostCommonPaymentMethod(for: category, in: recentSameBucket) ?? "Cash"
            )
        }

        return SmartDefaultsSuggestion(category: "General", paymentMethod: "Cash")
    }

    private func fetchRecentExpenses(
        modelContext: ModelContext,
        kind: TransactionKind,
        currencyCode: String,
        dateAfter: Date
    ) -> [Expense] {
        let kindRaw = kind.rawValue

        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { exp in
                exp.kindRaw == kindRaw && exp.currencyCode == currencyCode && exp.occurredAt >= dateAfter
            },
            sortBy: [SortDescriptor(\Expense.occurredAt, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func amountRange(for amount: Decimal) -> ClosedRange<Decimal> {
        let n = (amount as NSDecimalNumber).doubleValue
        switch n {
        case ..<100: return 0...120
        case 100..<300: return 80...360
        case 300..<1000: return 240...1200
        case 1000..<5000: return 800...6000
        default: return 4000...2000000
        }
    }

    private func mostCommonCategory(in expenses: [Expense], where filter: (Expense) -> Bool) -> String? {
        var counts: [String: Int] = [:]
        for exp in expenses where filter(exp) {
            counts[exp.category, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func mostCommonPaymentMethod(for category: String, in expenses: [Expense]) -> String? {
        var counts: [String: Int] = [:]
        for exp in expenses where exp.category == category {
            counts[exp.paymentMethod, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
