import Foundation

/**
 View model for **host-game.stencil** in edit mode.
 */
struct EditActivityViewModel: Codable {
    
    let base: BaseViewModel
    let id: String
    let type: String
    let playerCountOptions: [Int]
    let playerCount: Int
    let minPlayerCount: Int
    let prereservedSeatsOptions: [Int]
    let prereservedSeats: Int
    let info: String
    
    struct DateViewModel: Codable {
        
        let day: Int
        let month: Int
        let year: Int
        let hour: Int
        let minute: Int
        
        init(_ components: DateComponents) {
            day = components.day!
            month = components.month!
            year = components.year!
            hour = components.hour!
            minute = components.minute!
        }
    }
    
    let date: DateViewModel
    
    init(base: BaseViewModel, activity: Activity, type: String) throws {
        guard let id = activity.id,
              activity.game != nil else {
            throw log(ServerError.unpersistedEntity)
        }
        self.base = base
        self.id = id.hexString
        self.type = "edit-\(type)"
        self.playerCountOptions = Array(activity.game!.playerCount)
        self.playerCount = activity.playerCount.upperBound
        self.minPlayerCount = activity.playerCount.lowerBound
        self.prereservedSeatsOptions = Array(0..<activity.game!.playerCount.upperBound)
        self.prereservedSeats = activity.prereservedSeats
        self.info = activity.info
        let components = Calendar(identifier: .gregorian).dateComponents(in: Settings.timeZone, from: activity.date)
        self.date = DateViewModel(components)
    }
}
