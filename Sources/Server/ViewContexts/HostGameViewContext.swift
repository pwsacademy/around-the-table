import Foundation

/*
 View context for `host-game.stencil`.
 */
struct HostGameViewContext: ViewContext {
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], user: User, game: GameData) {
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
            "prereservedSeatsOptions": Array(0..<game.playerCount.upperBound) // Make sure at least one seat is left.
        ]
        if let location = user.location {
            contents["location"] = [
                "address": location.address,
                "city": location.city
            ]
        }
    }
    
    private func gameDataMapper(_ game: GameData) -> [String: Any] {
        var output: [String: Any] = [
            "id": game.id
        ]
        if let names = game.names, names.count > 1 {
            output["nameOptions"] = names
        } else {
            output["name"] = game.name
        }
        if game.playerCount.count == 1 {
            output["playerCount"] = game.playerCount.lowerBound
        } else {
            output["playerCountOptions"] = Array(game.playerCount)
        }
        return output
    }
}
