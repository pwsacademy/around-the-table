import Foundation

/**
 View model for **games.stencil**.
 */
struct ActivitiesViewModel: Codable {
    
    let base: BaseViewModel
    
    struct UserViewModel: Codable {
        
        let name: String
        
        init(_ user: User) {
            self.name = user.name
        }
    }
    
    struct ActivityViewModel: Codable {
        
        let id: String
        let host: UserViewModel
        let name: String
        let picture: String
        let availableSeats: Int
        let date: String
        let location: Location
        let distance: Int
        
        init(_ activity: Activity) throws {
            guard let id = activity.id,
                  let distance = activity.distance else {
                throw log(ServerError.unpersistedEntity)
            }
            self.id = id.hexString
            self.host = UserViewModel(activity.host)
            self.name = activity.name
            self.picture = activity.picture?.absoluteString ?? Settings.defaultGamePicture
            self.availableSeats = activity.availableSeats
            self.date = activity.date.formatted(dateStyle: .full)
            self.location = activity.location
            self.distance = Int(ceil(distance / 1000)) // in km
        }
    }
    
    /// A selection of most recently added activities.
    let newest: [ActivityViewModel]
    
    /// A selection of upcoming activities.
    let upcoming: [ActivityViewModel]
    
    /// A selection of activities closest to the user.
    let closest: [ActivityViewModel]
    
    /**
     Initializes an `ActivitiesViewModel` with the given activities.
     */
    init(base: BaseViewModel, newest: [Activity], upcoming: [Activity], closest: [Activity]) throws {
        self.base = base
        self.newest = try newest.map(ActivityViewModel.init)
        self.upcoming = try upcoming.map(ActivityViewModel.init)
        self.closest = try closest.map(ActivityViewModel.init)
    }
}
