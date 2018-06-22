import Foundation

/**
 View model for **my-games.stencil**.
 */
struct MyActivitiesViewModel: Codable {
    
    let base: BaseViewModel
    
    struct UserViewModel: Codable {
        
        let name: String
        let picture: String
        
        init(_ user: User) {
            self.name = user.name
            self.picture = user.picture?.absoluteString ?? Settings.defaultProfilePicture
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
    
    struct HostedActivity: Codable {
        
        let activity: ActivityViewModel
        let players: [UserViewModel]
        let pendingRegistrationCount: Int
    }
    
    let hosted: [HostedActivity]
    
    struct JoinedActivity: Codable {
        
        let activity: ActivityViewModel
        let players: [UserViewModel]
    }
    
    let joined: [JoinedActivity]
    
    init(base: BaseViewModel, hosted: [Activity], joined: [Activity]) throws {
        self.base = base
        self.hosted = try hosted.map {
            HostedActivity(activity: try ActivityViewModel($0),
                           players: $0.players.map(UserViewModel.init),
                           pendingRegistrationCount: $0.pendingRegistrations.count)
        }
        self.joined = try joined.map {
            JoinedActivity(activity: try ActivityViewModel($0),
                           players: $0.players.map(UserViewModel.init))
        }
    }
}
