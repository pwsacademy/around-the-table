import Foundation
import HTMLEntities

/**
 View model for **activities-grid.stencil** and **activities-list.stencil**.
 */
struct ActivitiesViewModel: Codable {
    
    let base: BaseViewModel
    
    let sort: String
    
    struct UserViewModel: Codable {
        
        let name: String
        
        init(_ user: User) {
            self.name = user.name.htmlEscape()
        }
    }
    
    struct ActivityViewModel: Codable {
        
        let id: Int
        let host: UserViewModel
        let name: String
        let picture: String
        let userHasJoined: Bool
        let userIsPending: Bool
        let availableSeats: Int
        let longDate: String
        let shortDate: String
        let time: String
        let location: Location
        let distance: Int
        
        init(_ activity: Activity, for user: User?) throws {
            guard let id = activity.id,
                  let distance = activity.distance else {
                throw log(ServerError.unpersistedEntity)
            }
            self.id = id
            host = UserViewModel(activity.host)
            name = activity.name
            picture = activity.picture?.absoluteString ?? Settings.defaultGamePicture
            if let user = user {
                userHasJoined = user == activity.host || activity.players.contains(user)
                userIsPending = activity.pendingRegistrations.contains { $0.player == user }
            } else {
                userHasJoined = false
                userIsPending = false
            }
            availableSeats = activity.availableSeats
            longDate = activity.date.formatted(format: "EEEE d MMMM")
            shortDate = activity.date.formatted(format: "E d MMMM") // abbreviated weekday
            time = activity.date.formatted(timeStyle: .short)
            location = activity.location
            self.distance = Int(ceil(distance / 1000)) // in km
        }
    }
    
    let activities: [ActivityViewModel]
    
    /**
     Initializes an `ActivitiesViewModel` with the given activities.
     */
    init(base: BaseViewModel, sort: String, activities: [Activity], for user: User?) throws {
        self.base = base
        self.sort = sort
        self.activities = try activities.map { try ActivityViewModel($0, for: user) }
    }
}
