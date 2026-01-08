import Foundation
import Supabase
import SwiftData

/// Service for syncing expenses with Supabase
@MainActor
final class SupabaseSyncService {
    
    private let client: SupabaseClient
    private let modelContext: ModelContext
    
    enum SyncError: LocalizedError {
        case notAuthenticated
        case syncFailed(String)
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "User is not authenticated"
            case .syncFailed(let message):
                return "Sync failed: \(message)"
            case .networkError:
                return "Network connection error"
            }
        }
    }
    
    init(client: SupabaseClient = SupabaseClientProvider.shared.client, modelContext: ModelContext) {
        self.client = client
        self.modelContext = modelContext
    }
    
    // MARK: - Expense Sync
    
    /// Sync all local expenses to Supabase
    func syncExpensesToCloud() async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SyncError.notAuthenticated
        }
        
        // Get all local expenses
        let descriptor = FetchDescriptor<Expense>()
        let localExpenses = try modelContext.fetch(descriptor)
        
        for expense in localExpenses {
            try await uploadExpense(expense, userId: userId)
        }
    }
    
    /// Download expenses from Supabase
    func downloadExpensesFromCloud() async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SyncError.notAuthenticated
        }
        
        struct ExpenseDTO: Codable {
            let id: UUID
            let kind: String
            let amount: String
            let currencyCode: String
            let title: String?
            let notes: String?
            let category: String
            let paymentMethod: String?
            let emotionalTag: String?
            let approvalStatus: String
            let occurredAt: Date
            let createdAt: Date
            let updatedAt: Date
            
            enum CodingKeys: String, CodingKey {
                case id, kind, amount, category, title, notes
                case currencyCode = "currency_code"
                case paymentMethod = "payment_method"
                case emotionalTag = "emotional_tag"
                case approvalStatus = "approval_status"
                case occurredAt = "occurred_at"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
        
        let response: [ExpenseDTO] = try await client
            .from("expenses")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        // Create or update local expenses
        for dto in response {
            // Check if expense already exists
            let predicate = #Predicate<Expense> { expense in
                expense.id == dto.id
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            let existing = try modelContext.fetch(descriptor).first
            
            if existing == nil {
                // Create new expense
                let expense = Expense(
                    id: dto.id,
                    createdAt: dto.createdAt,
                    occurredAt: dto.occurredAt,
                    kind: TransactionKind(rawValue: dto.kind) ?? .expense,
                    approvalStatus: ExpenseApprovalStatus(rawValue: dto.approvalStatus) ?? .pending,
                    amount: Decimal(string: dto.amount) ?? 0,
                    currencyCode: dto.currencyCode,
                    title: dto.title ?? "",
                    notes: dto.notes,
                    category: dto.category,
                    paymentMethod: dto.paymentMethod ?? "",
                    emotionalTag: EmotionalTag(rawValue: dto.emotionalTag ?? "none") ?? .none
                )
                modelContext.insert(expense)
            }
        }
        
        try modelContext.save()
    }
    
    private func uploadExpense(_ expense: Expense, userId: UUID) async throws {
        struct ExpenseUpload: Encodable {
            let id: UUID
            let userId: UUID
            let kind: String
            let amount: String
            let currencyCode: String
            let title: String?
            let notes: String?
            let category: String
            let paymentMethod: String?
            let emotionalTag: String
            let approvalStatus: String
            let occurredAt: Date
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case kind, amount, category, title, notes
                case currencyCode = "currency_code"
                case paymentMethod = "payment_method"
                case emotionalTag = "emotional_tag"
                case approvalStatus = "approval_status"
                case occurredAt = "occurred_at"
            }
        }
        
        let upload = ExpenseUpload(
            id: expense.id,
            userId: userId,
            kind: expense.kind.rawValue,
            amount: "\(expense.amount)",
            currencyCode: expense.currencyCode,
            title: expense.title.isEmpty ? nil : expense.title,
            notes: expense.notes,
            category: expense.category,
            paymentMethod: expense.paymentMethod.isEmpty ? nil : expense.paymentMethod,
            emotionalTag: expense.emotionalTag.rawValue,
            approvalStatus: expense.approvalStatus.rawValue,
            occurredAt: expense.occurredAt
        )
        
        try await client
            .from("expenses")
            .upsert(upload)
            .execute()
    }
    
    /// Delete expense from cloud
    func deleteExpenseFromCloud(_ expenseId: UUID) async throws {
        try await client
            .from("expenses")
            .delete()
            .eq("id", value: expenseId.uuidString)
            .execute()
    }
    
    // MARK: - Budget Sync
    
    func syncBudgetsToCloud() async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SyncError.notAuthenticated
        }
        
        let descriptor = FetchDescriptor<Budget>()
        let budgets = try modelContext.fetch(descriptor)
        
        for budget in budgets {
            // Upload each category budget as a separate row
            for (category, amount) in budget.categoryBudgets {
                try await uploadCategoryBudget(
                    budgetId: budget.id,
                    userId: userId,
                    category: category,
                    amount: amount,
                    monthKey: budget.monthKey
                )
            }
        }
    }
    
    private func uploadCategoryBudget(budgetId: UUID, userId: UUID, category: String, amount: Decimal, monthKey: Date) async throws {
        struct BudgetUpload: Encodable {
            let id: UUID
            let userId: UUID
            let category: String
            let amount: String
            let monthKey: Date
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case category, amount
                case monthKey = "month_key"
            }
        }
        
        // Create a unique ID for each category budget entry
        let entryId = UUID()
        
        let upload = BudgetUpload(
            id: entryId,
            userId: userId,
            category: category,
            amount: "\(amount)",
            monthKey: monthKey
        )
        
        try await client
            .from("budgets")
            .upsert(upload)
            .execute()
    }
    
    // MARK: - Goal Sync
    
    func syncGoalsToCloud() async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SyncError.notAuthenticated
        }
        
        let descriptor = FetchDescriptor<SavingsGoal>()
        let goals = try modelContext.fetch(descriptor)
        
        for goal in goals {
            try await uploadGoal(goal, userId: userId)
        }
    }
    
    private func uploadGoal(_ goal: SavingsGoal, userId: UUID) async throws {
        struct GoalUpload: Encodable {
            let id: UUID
            let userId: UUID
            let name: String
            let targetAmount: String
            let currentAmount: String
            let currencyCode: String
            let targetDate: Date?
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case name
                case targetAmount = "target_amount"
                case currentAmount = "current_amount"
                case currencyCode = "currency_code"
                case targetDate = "target_date"
            }
        }
        
        let upload = GoalUpload(
            id: goal.id,
            userId: userId,
            name: goal.name,
            targetAmount: "\(goal.targetAmount)",
            currentAmount: "\(goal.currentAmount)",
            currencyCode: "USD", // Default currency since model doesn't have this field
            targetDate: goal.deadline
        )
        
        try await client
            .from("goals")
            .upsert(upload)
            .execute()
    }
    
    // MARK: - Template Sync
    
    func syncTemplatesToCloud() async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw SyncError.notAuthenticated
        }
        
        let descriptor = FetchDescriptor<ExpenseTemplate>()
        let templates = try modelContext.fetch(descriptor)
        
        for template in templates {
            try await uploadTemplate(template, userId: userId)
        }
    }
    
    private func uploadTemplate(_ template: ExpenseTemplate, userId: UUID) async throws {
        struct TemplateUpload: Encodable {
            let id: UUID
            let userId: UUID
            let name: String
            let amount: String
            let category: String
            let paymentMethod: String?
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case name, amount, category
                case paymentMethod = "payment_method"
            }
        }
        
        let upload = TemplateUpload(
            id: template.id,
            userId: userId,
            name: template.name,
            amount: "\(template.amount)",
            category: template.category,
            paymentMethod: template.paymentMethod.isEmpty ? nil : template.paymentMethod
        )
        
        try await client
            .from("expense_templates")
            .upsert(upload)
            .execute()
    }
    
    // MARK: - Full Sync
    
    /// Perform a full bidirectional sync
    func performFullSync() async throws {
        // Download from cloud first
        try await downloadExpensesFromCloud()
        
        // Upload any local changes
        try await syncExpensesToCloud()
        try await syncBudgetsToCloud()
        try await syncGoalsToCloud()
        try await syncTemplatesToCloud()
    }
}
