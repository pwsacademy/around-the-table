/**
 View model for **edit-activity-playercount.stencil**.
 */
struct EditActivityPlayerCountViewModel: Codable {
    
    let base: BaseViewModel
    let id: String
    let playerCountOptions: [Int]
    let playerCount: Int
    let minPlayerCount: Int
    let prereservedSeatsOptions: [Int]
    let prereservedSeats: Int
    
    init(base: BaseViewModel, activity: Activity) throws {
        guard let id = activity.id,
              activity.game != nil else {
            throw log(ServerError.unpersistedEntity)
        }
        self.base = base
        self.id = id.hexString
        self.playerCountOptions = Array(activity.game!.playerCount)
        self.playerCount = activity.playerCount.upperBound
        self.minPlayerCount = activity.playerCount.lowerBound
        self.prereservedSeatsOptions = Array(0..<activity.game!.playerCount.upperBound)
        self.prereservedSeats = activity.prereservedSeats
    }
}
