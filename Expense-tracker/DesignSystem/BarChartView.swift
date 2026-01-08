import SwiftUI
import Charts

/// Bar chart for comparing values across categories or time periods
struct BarChartView: View {
    let data: [BarData]
    var orientation: Orientation = .vertical
    var color: Color = ColorTokens.primary
    var chartHeight: CGFloat = 200
    
    enum Orientation {
        case vertical
        case horizontal
    }
    
    struct BarData: Identifiable {
        let id = UUID()
        let label: String
        let value: Decimal
        
        var valueDouble: Double {
            NSDecimalNumber(decimal: value).doubleValue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if data.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.fill",
                    title: "No Data",
                    subtitle: "Add expenses to see comparison"
                )
                .frame(height: chartHeight)
            } else {
                Chart(data) { item in
                    if orientation == .vertical {
                        BarMark(
                            x: .value("Category", item.label),
                            y: .value("Amount", item.valueDouble)
                        )
                        .foregroundStyle(color)
                        .cornerRadius(Spacing.radiusSmall)
                    } else {
                        BarMark(
                            x: .value("Amount", item.valueDouble),
                            y: .value("Category", item.label)
                        )
                        .foregroundStyle(color)
                        .cornerRadius(Spacing.radiusSmall)
                    }
                }
                .chartXAxis {
                    if orientation == .vertical {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(Typography.captionSmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    } else {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(ColorTokens.chartGrid)
                            AxisValueLabel()
                                .font(Typography.captionMedium)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    }
                }
                .chartYAxis {
                    if orientation == .vertical {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(ColorTokens.chartGrid)
                            AxisValueLabel()
                                .font(Typography.captionMedium)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    } else {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(Typography.captionSmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    }
                }
                .frame(height: chartHeight)
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        BarChartView(
            data: [
                .init(label: "Food", value: 450),
                .init(label: "Transport", value: 200),
                .init(label: "Shopping", value: 350),
                .init(label: "Bills", value: 500),
            ],
            orientation: .vertical
        )
        
        BarChartView(
            data: [
                .init(label: "Jan", value: 1200),
                .init(label: "Feb", value: 950),
                .init(label: "Mar", value: 1450),
            ],
            orientation: .horizontal,
            color: ColorTokens.success
        )
    }
    .padding()
}
