import Foundation

extension Dictionary {

    mutating func append(_ dictionary: [Key: Value]) {
        for (key, value) in dictionary {
            self[key] = value
        }
    }
    
    func appending(_ dictionary: [Key: Value]) -> [Key: Value] {
        var result = self
        for (key, value) in dictionary {
            result[key] = value
        }
        return result
    }
}

extension Sequence where Iterator.Element: Equatable {
    
    func withoutDuplicates() -> [Iterator.Element] {
        return reduce([]) {
            elements, element in
            return elements.contains(element) ? elements : elements + [element]
        }
    }
}

extension Date {
    
    /*
     Format a date using the current locale and time zone.
     */
    func formatted(dateStyle: DateFormatter.Style = .none, timeStyle: DateFormatter.Style = .none) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Settings.locale)
        formatter.timeZone = Settings.timeZone
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    /*
     Format a date using a custom format.
     */
    func formatted(format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Settings.locale)
        formatter.timeZone = Settings.timeZone
        formatter.setLocalizedDateFormatFromTemplate(format)
        return formatter.string(from: self)
    }
}
