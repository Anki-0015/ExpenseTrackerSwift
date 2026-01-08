import Foundation
import SwiftData

struct DataIntegrityFinding: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case potentialDuplicate
        case outlier
        case monthlyHealth
    }

    let id: UUID
    let kind: Kind
    let title: String
    let detail: String
    let expenseId: UUID?

    init(kind: Kind, title: String, detail: String, expenseId: UUID? = nil) {
        self.id = UUID()
        self.kind = kind
        self.title = title
        self.detail = detail
        self.expenseId = expenseId
    }
}

struct DataIntegrityService {
    func runMonthlyHealthCheck(monthKey: Date, modelContext: ModelContext, currencyCode: String) -> [DataIntegrityFinding] {
        var findings: [DataIntegrityFinding] = []

        findings.append(contentsOf: detectDuplicates(modelContext: modelContext, monthKey: monthKey, currencyCode: currencyCode))
        findings.append(contentsOf: detectOutliers(modelContext: modelContext, monthKey: monthKey, currencyCode: currencyCode))

        if findings.isEmpty {
            findings.append(DataIntegrityFinding(kind: .monthlyHealth, title: "Data looks healthy", detail: "No duplicates or outliers detected for this month."))
        }

        return findings
    }

    func detectDuplicates(modelContext: ModelContext, monthKey: Date, currencyCode: String) -> [DataIntegrityFinding] {
        let calendar = Calendar.current
        guard let end = calendar.date(byAdding: .month, value: 1, to: monthKey) else { return [] }

        // Keep SwiftData predicate simple for compiler + performance.
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { exp in
                exp.currencyCode == currencyCode && exp.occurredAt >= monthKey && exp.occurredAt < end
            },
            sortBy: [SortDescriptor(\Expense.occurredAt, order: .forward)]
        )

        let expenses = ((try? modelContext.fetch(descriptor)) ?? []).filter {
            $0.kindRaw == TransactionKind.expense.rawValue
        }
        guard expenses.count >= 2 else { return [] }

        var findings: [DataIntegrityFinding] = []

        for i in 0..<(expenses.count - 1) {
            let a = expenses[i]
            let b = expenses[i + 1]

            let sameCategory = a.category == b.category
            let sameAmount = a.amount == b.amount
            let delta = abs(a.occurredAt.timeIntervalSince(b.occurredAt))

            if sameCategory && sameAmount && delta <= 5 * 60 {
                let title = "Possible duplicate: \(a.category)"
                let detail = "Two entries with the same amount within 5 minutes. Review and discard if needed."
                findings.append(DataIntegrityFinding(kind: .potentialDuplicate, title: title, detail: detail, expenseId: b.id))
            }
        }

        return findings
    }

    func detectOutliers(modelContext: ModelContext, monthKey: Date, currencyCode: String) -> [DataIntegrityFinding] {
        let calendar = Calendar.current
        guard let end = calendar.date(byAdding: .month, value: 1, to: monthKey) else { return [] }

        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { exp in
                exp.currencyCode == currencyCode && exp.occurredAt >= monthKey && exp.occurredAt < end
            }
        )

        let expenses = ((try? modelContext.fetch(descriptor)) ?? []).filter {
            $0.kindRaw == TransactionKind.expense.rawValue && $0.approvalRaw == ExpenseApprovalStatus.approved.rawValue
        }
        let grouped = Dictionary(grouping: expenses, by: { $0.category })

        var findings: [DataIntegrityFinding] = []

        for (category, items) in grouped {
            let values = items.map { (item: $0, value: (NSDecimalNumber(decimal: $0.amount).doubleValue)) }
            guard values.count >= 8 else { continue }

            let sorted = values.map { $0.value }.sorted()
            let q1 = percentile(sorted, p: 0.25)
            let q3 = percentile(sorted, p: 0.75)
            let iqr = max(1e-9, q3 - q1)
            let highFence = q3 + 2.5 * iqr

            for v in values where v.value > highFence {
                findings.append(
                    DataIntegrityFinding(
                        kind: .outlier,
                        title: "Outlier in \(category)",
                        detail: "This expense is unusually high compared to your typical \(category) spending.",
                        expenseId: v.item.id
                    )
                )
            }
        }

        return findings
    }

    private func percentile(_ sorted: [Double], p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let clamped = max(0, min(1, p))
        let idx = clamped * Double(sorted.count - 1)
        let lower = Int(floor(idx))
        let upper = Int(ceil(idx))
        if lower == upper { return sorted[lower] }
        let weight = idx - Double(lower)
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }
}
