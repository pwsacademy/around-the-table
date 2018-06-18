import Foundation

/**
 Form submitted to edit an activity.
 */
struct EditActivityForm: Codable {
    
    let type: String
    
    let playerCount: Int?
    let minPlayerCount: Int?
    let prereservedSeats: Int?
    
    let day: Int?
    let month: Int?
    let year: Int?
    let hour: Int?
    let minute: Int?
    
    let deadlineType: String?
    
    let address: String?
    let city: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    
    let info: String?
    
    enum Result {
        
        case players(count: Int, min: Int, prereserved: Int)
        case date(Date)
        case deadline(String)
        case address(Location)
        case info(String)
        case cancel
        case invalid
    }
    
    var result: Result {
        switch type {
        case "edit-players":
            guard let playerCount = playerCount,
                  let minPlayerCount = minPlayerCount,
                  let prereservedSeats = prereservedSeats,
                  minPlayerCount <= playerCount,
                  prereservedSeats <= playerCount else {
                return .invalid
            }
            return .players(count: playerCount, min: minPlayerCount, prereserved: prereservedSeats)
        case "edit-datetime":
            guard let day = day,
                  let month = month,
                  let year = year,
                  let hour = hour,
                  let minute = minute else {
                return .invalid
            }
            let calendar = Calendar(identifier: .gregorian)
            var components = DateComponents()
            components.calendar = calendar
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
                return .invalid
            }
            return .date(date)
        case "edit-deadline":
            guard let deadlineType = deadlineType,
                  ["one hour", "one day", "two days", "one week"].contains(deadlineType) else {
                return .invalid
            }
            return .deadline(deadlineType)
        case "edit-address":
            guard let address = address,
                  let city = city,
                  let country = country,
                  let latitude = latitude,
                  let longitude = longitude else {
                return .invalid
            }
            return .address(Location(coordinates: Coordinates(latitude: latitude, longitude: longitude),
                                     address: address, city: city, country: country))
        case "edit-info":
            guard let info = info else {
                return .invalid
            }
            return .info(info)
        case "cancel":
            return .cancel
        default:
            return .invalid
        }
    }
}
