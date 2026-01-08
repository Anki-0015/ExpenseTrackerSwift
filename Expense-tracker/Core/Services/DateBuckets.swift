import Foundation

enum DateBuckets {
    /// Returns the start date of the user's "month bucket".
    /// If `fiscalStartDay` is 1, this is the first day of the calendar month.
    /// If `fiscalStartDay` is N (2...28), the bucket starts on day N.
    static func monthKey(for date: Date, fiscalStartDay: Int, calendar: Calendar = .current) -> Date {
        let startDay = max(1, min(28, fiscalStartDay))

        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        let day = comps.day ?? 1

        // If we're before the fiscal start day, bucket belongs to previous month.
        if day < startDay {
            if let prev = calendar.date(byAdding: .month, value: -1, to: date) {
                comps = calendar.dateComponents([.year, .month], from: prev)
            }
        } else {
            comps = calendar.dateComponents([.year, .month], from: date)
        }

        comps.day = startDay
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps) ?? date
    }

    static func monthKey(for date: Date, calendar: Calendar = .current) -> Date {
        monthKey(for: date, fiscalStartDay: 1, calendar: calendar)
    }

    static func monthRange(for date: Date, fiscalStartDay: Int, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let start = monthKey(for: date, fiscalStartDay: fiscalStartDay, calendar: calendar)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? calendar.date(byAdding: .day, value: 30, to: start) ?? date
        return (start, end)
    }

    static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }
}
