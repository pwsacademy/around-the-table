import Foundation

/*
 View context for `host-game.stencil` when used for editing a game.
 */
struct EditGameViewContext: ViewContext {
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], game: Game, type: String) throws {
        self.base = base
        contents["id"] = game.id
        contents["type"] = "edit-\(type)"
        switch type {
        case "players":
            guard let gameData = try GameDataRepository().gameData(forID: game.data.id) else {
                try logAndThrow(ServerError.invalidState)
            }
            contents["game"] = [
                "playerCountOptions": Array(gameData.playerCount),
                "playerCount": game.data.playerCount.upperBound,
                "minPlayerCount": game.data.playerCount.lowerBound
            ]
            contents["prereservedSeatsOptions"] = Array(0..<gameData.playerCount.upperBound)
            contents["prereservedSeats"] = game.prereservedSeats
        case "datetime":
            let dateComponents = Calendar(identifier: .gregorian).dateComponents(in: Settings.timeZone, from: game.date)
            contents["date"] = [
                "day": dateComponents.day!,
                "month": dateComponents.month!,
                "year": dateComponents.year!,
                "hour": dateComponents.hour!,
                "minute": dateComponents.minute!
            ]
        case "address":
            if let location = game.host.location {
                contents["location"] = [
                    "address": location.address,
                    "city": location.city
                ]
            }
        case "info":
            contents["info"] = game.info
        default:
            break
        }
    }
}
