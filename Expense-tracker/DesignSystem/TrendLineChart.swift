import SwiftUI
import Charts

/// Line chart for showing spending trends over time
struct TrendLineChart: View {
    let data: [DataPoint]
    var lineColor: Color = ColorTokens.primary
    var showPoints: Bool = true
    var chartHeight: CGFloat = 200
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Decimal
        
        var amountValue: Double {
            NSDecimalNumber(decimal: amount).doubleValue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if data.isEmpty {
                EmptyStateView(
                    icon: "chart.xyaxis.line",
                    title: "No Data",
                    subtitle: "Track expenses to see trends"
                )
                .frame(height: chartHeight)
            } else {
                Chart(data) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", item.amountValue)
                    )
                    .foregroundStyle(lineColor)
                    .interpolationMethod(.catmullRom)
                    
                    if showPoints {
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Amount", item.amountValue)
                        )
                        .foregroundStyle(lineColor)
                    }
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", item.amountValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(ColorTokens.chartGrid)
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(Typography.captionMedium)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(ColorTokens.chartGrid)
                        AxisValueLabel()
                            .font(Typography.captionMedium)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                .frame(height: chartHeight)
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    
    return TrendLineChart(
        data: [
            .init(date: calendar.date(byAdding: .day, value: -6, to: today)!, amount: 45),
            .init(date: calendar.date(byAdding: .day, value: -5, to: today)!, amount: 65),
            .init(date: calendar.date(byAdding: .day, value: -4, to: today)!, amount: 52),
            .init(date: calendar.date(byAdding: .day, value: -3, to: today)!, amount: 78),
            .init(date: calendar.date(byAdding: .day, value: -2, to: today)!, amount: 43),
            .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, amount: 90),
            .init(date: today, amount: 55),
        ]
    )
    .padding()
}
