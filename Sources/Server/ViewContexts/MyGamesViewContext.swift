import Foundation

/*
 View context for `my-games.stencil`.
 */
struct MyGamesViewContext: ViewContext {
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], hosted: [Game], playing: [Game]) throws {
        self.base = base
        contents = [
            "hostedGames": try hosted.map(hostedGameMapper),
            "playingGames": try playing.map(playingGameMapper)
        ]
    }
    
    private func hostedGameMapper(_ game: Game) throws -> [String: Any] {
        guard let id = game.id else {
            try logAndThrow(ServerError.invalidState)
        }
        let players = try UserRepository().players(for: game)
        let requests = try RequestRepository().unapprovedRequestCount(for: game)
        return [
            "id": id,
            "data": [
                "name": game.data.name,
                "playerCount": game.data.playerCount.upperBound,
                "minPlayingTime": game.data.playingTime.lowerBound,
                "maxPlayingTime": game.data.playingTime.upperBound,
                "picture": game.data.picture?.absoluteString ?? Settings.defaultGamePicture,
            ],
            "date": formatted(game.date, dateStyle: .full),
            "players": players.map { ["picture": $0.picture?.absoluteString ?? Settings.defaultProfilePicture ] },
            "availableSeats": game.availableSeats,
            "requests": requests
        ]
    }
    
    private func playingGameMapper(_ game: Game) throws -> [String: Any] {
        guard let id = game.id,
              let distance = game.location.distance else {
            try logAndThrow(ServerError.invalidState)
        }
        let players = try UserRepository().players(for: game)
        return [
            "id": id,
            "data": [
                "name": game.data.name,
                "playerCount": game.data.playerCount.upperBound,
                "minPlayingTime": game.data.playingTime.lowerBound,
                "maxPlayingTime": game.data.playingTime.upperBound,
                "picture": game.data.picture?.absoluteString ?? Settings.defaultGamePicture,
            ],
            "host": [
                "name": game.host.name,
                "picture": game.host.picture?.absoluteString ?? Settings.defaultProfilePicture
            ],
            "date": formatted(game.date, dateStyle: .full),
            "players": players.map { ["picture": $0.picture?.absoluteString ?? Settings.defaultProfilePicture ] },
            "availableSeats": game.availableSeats,
            "distance": Int(ceil(distance / 1000))
        ]
    }
}
