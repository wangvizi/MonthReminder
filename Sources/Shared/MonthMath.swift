import Foundation

enum MonthMath {
    static var calendar: Calendar { .current }

    /// 当月天数
    static func daysInMonth(containing date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// 距离每月 day 号还剩几天（当天为 0）
    static func daysRemaining(untilDay day: Int, from date: Date) -> Int {
        let today = calendar.component(.day, from: date)
        let dim = daysInMonth(containing: date)
        let d = min(max(day, 1), dim)
        return d >= today ? d - today : d + dim - today
    }

    /// 本月已过百分比（含当天时间比例）
    static func monthProgress(at date: Date) -> Double {
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let dim = daysInMonth(containing: date)
        return (Double(day - 1) + Double(hour) / 24.0) / Double(dim)
    }

    /// 下一个零点
    static func nextMidnight(after date: Date) -> Date {
        calendar.nextDate(after: date,
                          matching: DateComponents(hour: 0, minute: 0),
                          matchingPolicy: .nextTime)
            ?? date.addingTimeInterval(3600)
    }
}
