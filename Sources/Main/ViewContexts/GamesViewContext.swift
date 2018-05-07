import Foundation

/*
 View context for `games.stencil`.
 */
struct GamesViewContext: ViewContext {
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], newest: [Game], upcoming: [Game], nearMe: [Game]) throws {
        self.base = base
        contents = [
            "newestGames": try newest.map(gameMapper),
            "upcomingGames": try upcoming.map(gameMapper),
            "gamesNearMe": try nearMe.map(gameMapper)
        ]
    }
    
    private func gameMapper(_ game: Game) throws -> [String: Any] {
        guard let id = game.id,
              let distance = game.location.distance else {
            try logAndThrow(ServerError.invalidState)
        }
        return [
            "id": id,
            "data": [
                "name": game.data.name,
                "picture": game.data.picture?.absoluteString ?? Settings.defaultGamePicture,
            ],
            "date": game.date.formatted(dateStyle: .full),
            "host": game.host.name,
            "city": game.location.city,
            "distance": Int(ceil(distance / 1000)),
            "seats": game.availableSeats
        ]
    }
}
