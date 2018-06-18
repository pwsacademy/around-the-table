import Foundation

// TODO: This can be removed once we switch to Swift 4.2.
extension BidirectionalCollection {
    
    public func lastIndex(where predicate: (Element) -> Bool) -> Index? {
        var i = endIndex
        while i != startIndex {
            formIndex(before: &i)
            if predicate(self[i]) {
                return i
            }
        }
        return nil
    }
}

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
