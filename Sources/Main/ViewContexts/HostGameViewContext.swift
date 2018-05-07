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
            "type": "create",
            "game": [
                "id": game.id,
                "nameOptions": game.names ?? [game.name],
                "playerCountOptions": Array(game.playerCount)
            ],
            "prereservedSeatsOptions": Array(0..<game.playerCount.upperBound), // Make sure at least one seat is left.
            "date": [
                "day": dateComponents.day!,
                "month": dateComponents.month!,
                "year": dateComponents.year!,
                "hour": dateComponents.hour!,
                "minute": dateComponents.minute!
            ]
        ]
        if let location = user.location {
            contents["location"] = [
                "address": location.address,
                "city": location.city,
                "country": location.country
            ]
        }
    }
}
