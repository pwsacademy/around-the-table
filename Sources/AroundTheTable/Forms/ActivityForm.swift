import Foundation

/**
 Form for submitting a new activity.
 */
struct ActivityForm: Codable {
    
    let game: Int
    let name: String
    let playerCount: Int
    let minPlayerCount: Int
    let prereservedSeats: Int
    
    let day: Int
    let month: Int
    let year: Int
    let hour: Int
    let minute: Int
    
    /// The activity's date.
    /// Returns `nil` if the form's fields do not represent a valid date.
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
              let date = components.date else {
            return nil
        }
        return date
    }
    
    let deadlineType: String
    
    /// The activity's deadline.
    /// Returns `nil` if either the deadline type or date is invalid.
    var deadline: Date? {
        guard let date = date else {
            return nil
        }
        let calendar = Calendar(identifier: .gregorian)
        switch deadlineType {
        case "one hour":
            return calendar.date(byAdding: .hour, value: -1, to: date)!
        case "one day":
            return calendar.date(byAdding: .day, value: -1, to: date)!
        case "two days":
            return calendar.date(byAdding: .day, value: -2, to: date)!
        case "one week":
            return calendar.date(byAdding: .weekOfYear, value: -1, to: date)!
        default:
            return nil
        }
    }
    
    let address: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    
    /// The activity's location.
    var location: Location {
        return Location(coordinates: Coordinates(latitude: latitude, longitude: longitude),
                        address: address,
                        city: city,
                        country: country)
    }
    
    let info: String
    
    /// Whether the form's fields are valid. Checks:
    /// - if the form does not contain an empty string for a required field,
    /// - if the player count is at least 1,
    /// - if the minimum player count is between 1 and the player count,
    /// - if the number of prereserved seats is at least 0 and less than the player count,
    /// - if the date is valid and in the future,
    /// - if the deadline is valid and in the future.
    var isValid: Bool {
        let checks = [
            // TODO: This can be improved using count(where:) once that's added to the Standard Library.
            ![name, address, city, country].map({ $0.isEmpty }).contains(true),
            playerCount >= 1,
            minPlayerCount >= 1 && minPlayerCount <= playerCount,
            prereservedSeats >= 0 && prereservedSeats < playerCount,
            date?.compare(Date()) == .orderedDescending,
            deadline?.compare(Date()) == .orderedDescending
        ]
        return !checks.contains(false)
    }
}
