import Foundation

/**
 Form for editing an activity's date and time.
 */
struct EditActivityDateTimeForm: Codable {
    
    let day: Int
    let month: Int
    let year: Int
    let hour: Int
    let minute: Int
    
    /// The new date.
    /// Returns `nil` if the form's fields do not represent a valid date,
    /// or if the date is not in the future.
    var date: Date? {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.day = day
        components.month = month
        components.year = year
        components.hour = hour
        components.minute = minute
        components.timeZone = Settings.timeZone
        guard components.isValidDate,
              let date = components.date,
              // The date must be in the future.
              date.compare(Date()) == .orderedDescending else {
            return nil
        }
        return date
    }
}
