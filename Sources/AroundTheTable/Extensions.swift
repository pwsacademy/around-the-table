import Foundation

private let calendar = Calendar(identifier: .gregorian)
private let formatter = DateFormatter()

extension Date {
    
    /**
     The date's day.
     
     Uses `Settings.timeZone` to determine the correct value.
     */
    var day: Int {
        return calendar.dateComponents(in: Settings.timeZone, from: self).day!
    }
    
    /**
     The date's month.
     
     Uses `Settings.timeZone` to determine the correct value.
     */
    var month: Int {
        return calendar.dateComponents(in: Settings.timeZone, from: self).month!
    }
    
    /**
     The date's year.
     
     Uses `Settings.timeZone` to determine the correct value.
     */
    var year: Int {
        return calendar.dateComponents(in: Settings.timeZone, from: self).year!
    }
    
    /**
     Returns the previous day.
     */
    var previous: Date {
        return calendar.date(byAdding: .day, value: -1, to: self)!
    }
    
    /**
     Returns the last day of a one-month window starting on the current date.
     
     Uses `Settings.timeZone` to determine the correct value.
     
     Some examples:
     Jan. 1 -> Jan. 31
     Jan. 2 -> Feb. 1
     Jan. 3 -> Feb. 2
     ...
     Jan. 28 -> Feb. 27
     Jan. 29 -> Feb. 28
     Jan. 30 -> Feb. 28
     Jan. 31 -> Feb. 28
     */
    var lastDayInWindow: Date {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: self)!
        if nextMonth.day < day {
            // Don't subtract a day if the next month has less days than the current one.
            return nextMonth
        }
        return calendar.date(byAdding: .day, value: -1, to: nextMonth)!
    }
    
    /**
     Returns a localized formatted date.
     
     Uses `Settings.locale` and `Settings.timeZone` by default.
     */
    func formatted(dateStyle: DateFormatter.Style = .none,
                   timeStyle: DateFormatter.Style = .none,
                   locale: Locale = Locale(identifier: Settings.locale),
                   timeZone: TimeZone = Settings.timeZone) -> String {
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    /**
     Returns a localized formatted date.
     
     Uses `Settings.locale` and `Settings.timeZone` by default.
     */
    func formatted(format: String,
                   locale: Locale = Locale(identifier: Settings.locale),
                   timeZone: TimeZone = Settings.timeZone) -> String {
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(format)
        return formatter.string(from: self)
    }
}
