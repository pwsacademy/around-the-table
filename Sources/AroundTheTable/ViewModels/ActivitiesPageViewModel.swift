import Foundation

/**
 View model for **games-page.stencil**.
 */
struct ActivitiesPageViewModel: Codable {
    
    let base: BaseViewModel
    
    enum PageType: String, Codable {
        
        case newest = "newest-games"
        case upcoming = "upcoming-games"
        case nearMe = "games-near-me"
    }
    
    let type: PageType
    
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
    
    
    let activities: [ActivityViewModel]
    
    /// A relative link to the previous page (if there is one).
    let previousPage: String?
    
    /// A relative link to the next page (if there is one).
    let nextPage: String?
    
    init(base: BaseViewModel, type: PageType, activities: [Activity], page: Int, hasNextPage: Bool) throws {
        self.base = base
        self.type = type
        self.activities = try activities.map(ActivityViewModel.init)
        self.previousPage = page > 0 ? "/web/\(type.rawValue)?page=\(page - 1)" : nil
        self.nextPage = hasNextPage ? "/web/\(type.rawValue)?page=\(page + 1)" : nil
    }
}
