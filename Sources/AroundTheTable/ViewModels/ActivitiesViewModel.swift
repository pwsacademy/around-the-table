import Foundation

/**
 View model for **activities-grid.stencil** and **activities-list.stencil**.
 */
struct ActivitiesViewModel: Codable {
    
    let base: BaseViewModel
    
    let sort: String
    
    struct UserViewModel: Codable {
        
        let name: String
        
        init(_ user: User) {
            self.name = user.name
        }
    }
    
    struct ActivityViewModel: Codable {
        
        let id: Int
        let host: UserViewModel
        let name: String
        let picture: String
        let thumbnail: String
        let availableSeats: Int
        let longDate: String
        let shortDate: String
        let time: String
        let location: Location
        let distance: Int
        
        init(_ activity: Activity) throws {
            guard let id = activity.id,
                  let distance = activity.distance else {
                throw log(ServerError.unpersistedEntity)
            }
            self.id = id
            self.host = UserViewModel(activity.host)
            self.name = activity.name
            self.picture = activity.picture?.absoluteString ?? Settings.defaultGamePicture
            self.thumbnail = activity.thumbnail?.absoluteString ?? Settings.defaultGameThumbnail
            self.availableSeats = activity.availableSeats
            self.longDate = activity.date.formatted(format: "EEEE d MMMM") 
            self.shortDate = activity.date.formatted(format: "E d MMMM") // abbreviated weekday
            self.time = activity.date.formatted(timeStyle: .short)
            self.location = activity.location
            self.distance = Int(ceil(distance / 1000)) // in km
        }
    }
    
    let activities: [ActivityViewModel]
    
    /**
     Initializes an `ActivitiesViewModel` with the given activities.
     */
    init(base: BaseViewModel, sort: String, activities: [Activity]) throws {
        self.base = base
        self.sort = sort
        self.activities = try activities.map(ActivityViewModel.init)
    }
}
