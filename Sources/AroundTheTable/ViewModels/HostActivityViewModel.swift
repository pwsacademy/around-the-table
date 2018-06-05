import Foundation

/**
 View model for **host-game.stencil**.
 */
struct HostActivityViewModel: Codable {
    
    let base: BaseViewModel
    let type: String
    let game: Int
    let nameOptions: [String]
    let playerCountOptions: [Int]
    let prereservedSeatsOptions: [Int]
    
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
    
    init(base: BaseViewModel, game: Game) {
        self.base = base
        type = "create"
        self.game = game.id
        nameOptions = game.names
        playerCountOptions = Array(game.playerCount)
        prereservedSeatsOptions = Array(0..<game.playerCount.upperBound)
        
        let calendar = Calendar(identifier: .gregorian)
        // Set the default date to tomorrow at 19:00.
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        var components = calendar.dateComponents(in: Settings.timeZone, from: tomorrow)
        components.hour = 19
        components.minute = 0
        date = DateViewModel(components)
    }
}
