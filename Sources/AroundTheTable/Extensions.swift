import Foundation

private let formatter = DateFormatter()

extension Date {
    
    /**
     The date's day.
     
     Uses `Settings.timeZone` to determine the correct value.
     */
    var day: Int {
        return Settings.calendar.dateComponents(in: Settings.timeZone, from: self).day!
    }
    
    /**
     The date's month.
     
     Uses `Settings.timeZone` to determine the correct value.
     */
    var month: Int {
        return Settings.calendar.dateComponents(in: Settings.timeZone, from: self).month!
    }
    
    /**
     The date's year.
     
     Uses `Settings.timeZone` to determine the correct value.
     */
    var year: Int {
        return Settings.calendar.dateComponents(in: Settings.timeZone, from: self).year!
    }
    
    /**
     Returns the previous day.
     */
    var previous: Date {
        return Settings.calendar.date(byAdding: .day, value: -1, to: self)!
    }
    
    /**
     Returns the date 30 days after this one.
     */
    var adding30Days: Date {
        return Settings.calendar.date(byAdding: .day, value: 30, to: self)!
    }
    
    /**
     Returns the date 30 days before this one.
     */
    var subtracting30Days: Date {
        return Settings.calendar.date(byAdding: .day, value: -30, to: self)!
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
