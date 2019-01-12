import Foundation

extension Date {
    
    /**
     Returns a localized formatted date.
     
     Uses `Settings.locale` and `Settings.timeZone` by default.
     */
    func formatted(dateStyle: DateFormatter.Style = .none,
                   timeStyle: DateFormatter.Style = .none,
                   locale: Locale = Locale(identifier: Settings.locale),
                   timeZone: TimeZone = Settings.timeZone) -> String {
        let formatter = DateFormatter()
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
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(format)
        return formatter.string(from: self)
    }
}
