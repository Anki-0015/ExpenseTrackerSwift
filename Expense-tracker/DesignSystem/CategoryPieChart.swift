import SwiftUI
import Charts

/// Reusable pie chart component for category breakdown
struct CategoryPieChart: View {
    let data: [CategoryData]
    var showLegend: Bool = true
    
    struct CategoryData: Identifiable {
        let id = UUID()
        let category: String
        let amount: Decimal
        let color: Color
        
        var amountValue: Double {
            NSDecimalNumber(decimal: amount).doubleValue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if data.isEmpty {
                EmptyStateView(
                    icon: "chart.pie.fill",
                    title: "No Data",
                    subtitle: "Add expenses to see category breakdown"
                )
                .frame(height: 200)
            } else {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Amount", item.amountValue),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartLegend(showLegend ? .visible : .hidden)
                
                if showLegend {
                    legendView
                }
            }
        }
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(data.prefix(5)) { item in
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    
                    Text(item.category)
                        .font(Typography.bodySmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                    
                    Spacer()
                    
                    Text(Formatters.currency(amount: item.amount, currencyCode: ""))
                        .font(Typography.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            
            if data.count > 5 {
                Text("+ \(data.count - 5) more")
                    .font(Typography.captionMedium)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(.top, Spacing.sm)
    }
}

#Preview {
    CategoryPieChart(
        data: [
            .init(category: "Food", amount: 450, color: ColorTokens.categoryColors[0]),
            .init(category: "Transport", amount: 200, color: ColorTokens.categoryColors[1]),
            .init(category: "Shopping", amount: 350, color: ColorTokens.categoryColors[2]),
            .init(category: "Entertainment", amount: 150, color: ColorTokens.categoryColors[3]),
        ]
    )
    .padding()
}
