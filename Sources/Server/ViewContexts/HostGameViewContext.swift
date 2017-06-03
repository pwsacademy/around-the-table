import Foundation

/*
 View context for `host-game.stencil`.
 */
struct HostGameViewContext: ViewContext {
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], game: GameData, prereservedSeats: Int? = nil, info: String = "", error: Bool = false) {
        self.base = base
        let calendar = Calendar(identifier: .gregorian)
        // Default to tomorrow at 19:00.
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        var dateComponents = calendar.dateComponents(in: Settings.timeZone, from: tomorrow)
        dateComponents.hour = 19
        dateComponents.minute = 0
        contents = [
            "game": gameDataMapper(game),
            "date": [
                "day": dateComponents.day!,
                "month": dateComponents.month!,
                "year": dateComponents.year!,
                "hour": dateComponents.hour!,
                "minute": dateComponents.minute!
            ],
            "info": info
        ]
        if let prereservedSeats = prereservedSeats {
            contents["prereservedSeats"] = prereservedSeats
        } else {
            // Calculate the possible number of seats to prereserve, making sure at least one seat is left.
            switch game.playerCount {
            case .fixed(amount: let players):
                contents["prereservedSeatsOptions"] = Array(0..<players)
            case .range(_, let max):
                contents["prereservedSeatsOptions"] = Array(0..<max)
            }
        }
        if error {
            contents["error"] = true
        }
    }
    
    private func gameDataMapper(_ game: GameData) -> [String: Any] {
        var output: [String: Any] = [
            "id": game.id
        ]
        if let names = game.names,
           names.count > 1 {
            output["nameOptions"] = names
        } else {
            output["name"] = game.name
        }
        switch game.playerCount {
        case .fixed(amount: let players):
            output["playerCount"] = players
        case .range(let min, let max):
            output["playerCountOptions"] = Array(min...max)
        }
        return output
    }
}
