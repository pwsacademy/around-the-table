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
              let distance = game.location.distance,
              let seats = game.availableSeats else {
            try logAndThrow(ServerError.invalidState)
        }
        return [
            "id": id,
            "data": [
                "name": game.data.name,
                "playerCount": game.data.playerCount.upperBound,
                "minPlayingTime": game.data.playingTime.lowerBound,
                "maxPlayingTime": game.data.playingTime.upperBound,
                "picture": game.data.picture?.absoluteString ?? Settings.defaultGamePicture,
            ],
            "date": formatted(game.date, dateStyle: .long),
            "host": [
                "name": game.host.name,
                "picture": game.host.picture?.absoluteString ?? Settings.defaultProfilePicture
            ],
            "distance": Int(ceil(distance / 1000)),
            "seats": seats
        ]
    }
}
