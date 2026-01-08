import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Expense.occurredAt, order: .reverse) private var expenses: [Expense]

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var occurredAt: Date = .now

    @State private var kind: TransactionKind = .expense

    @State private var category: String = "General"
    @State private var paymentMethod: String = "Cash"
    @State private var emotionalTag: EmotionalTag = .none

    @State private var notes: String = ""

    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Type", selection: $kind) {
                                ForEach(TransactionKind.allCases) { k in
                                    Text(k.rawValue.capitalized).tag(k)
                                }
                            }
                            .pickerStyle(.segmented)

                            HStack {
                                Text("Amount")
                                    .font(.headline)
                                Spacer()
                                Text(appState.settings.defaultCurrencyCode)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            TextField("0", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 36, weight: .semibold, design: .rounded))
                                .focused($focused)
                                .onChange(of: amountText) { _, _ in
                                    applySmartDefaultsIfPossible()
                                }

                            TextField("Title (optional)", text: $title)
                                .textInputAutocapitalization(.words)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            DatePicker("When", selection: $occurredAt)
                                .onChange(of: occurredAt) { _, _ in
                                    applySmartDefaultsIfPossible()
                                }

                            TextField("Category", text: $category)
                                .textInputAutocapitalization(.words)
                                .onSubmit { applySmartDefaultsIfPossible() }

                            TextField("Payment method", text: $paymentMethod)
                                .textInputAutocapitalization(.words)

                            Picker("Mood tag", selection: $emotionalTag) {
                                ForEach(EmotionalTag.allCases) { tag in
                                    Text(tag.rawValue.capitalized).tag(tag)
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            TextField("Optional", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }

                    Button {
                        save()
                    } label: {
                        Text("Add as pending")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .disabled(parsedAmount == nil)
                }
                .padding(16)
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    focused = true
                }
            }
        }
    }

    private var parsedAmount: Decimal? {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private func applySmartDefaultsIfPossible() {
        guard kind == .expense else { return }
        guard let amount = parsedAmount else { return }
        let engine = SmartDefaultsEngine()
        let suggestion = engine.suggest(
            input: .init(amount: amount, occurredAt: occurredAt),
            modelContext: modelContext,
            currencyCode: appState.settings.defaultCurrencyCode
        )

        // Keep user edits if they already typed something.
        if category == "General" { category = suggestion.category }
        if paymentMethod == "Cash" { paymentMethod = suggestion.paymentMethod }
    }

    private func save() {
        guard let amount = parsedAmount else { return }

        let exp = Expense(
            kind: kind,
            amount: amount,
            currencyCode: appState.settings.defaultCurrencyCode,
            title: title,
            notes: notes.isEmpty ? nil : notes,
            category: category,
            paymentMethod: paymentMethod,
            emotionalTag: emotionalTag
        )

        exp.occurredAt = occurredAt
        exp.approvalStatus = (kind == .expense) ? .pending : .approved

        modelContext.insert(exp)
        dismiss()
    }
}

#Preview {
    let container = PersistenceController.makeModelContainer(inMemory: true)
    return AddExpenseView()
        .environment(AppState())
        .modelContainer(container)
}
