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
        guard let id = game.id,
              let availableSeats = game.availableSeats,
              case .fixed(let playerCount) = game.data.playerCount else {
            try logAndThrow(ServerError.invalidState)
        }
        var data: [String: Any] = [
            "name": game.data.name,
            "playerCount": playerCount,
            "picture": game.data.picture?.absoluteString ?? Settings.defaultGamePicture,
        ]
        switch game.data.playingTime {
        case .average(time: let time):
            data["playingTime"] = time
        case .range(min: let minTime, max: let maxTime):
            data["minPlayingTime"] = minTime
            data["maxPlayingTime"] = maxTime
        }
        let players = try UserRepository().players(for: game)
        let requests = try RequestRepository().unapprovedRequestCount(for: game)
        return [
            "id": id,
            "data": data,
            "date": formatted(game.date, dateStyle: .long),
            "players": players.map { ["picture": $0.picture?.absoluteString ?? Settings.defaultProfilePicture ] },
            "availableSeats": availableSeats,
            "requests": requests
        ]
    }
    
    private func playingGameMapper(_ game: Game) throws -> [String: Any] {
        guard let id = game.id,
              let distance = game.location.distance,
              let availableSeats = game.availableSeats,
              case .fixed(let playerCount) = game.data.playerCount else {
            try logAndThrow(ServerError.invalidState)
        }
        var data: [String: Any] = [
            "name": game.data.name,
            "playerCount": playerCount,
            "picture": game.data.picture?.absoluteString ?? Settings.defaultGamePicture,
        ]
        switch game.data.playingTime {
        case .average(time: let time):
            data["playingTime"] = time
        case .range(min: let minTime, max: let maxTime):
            data["minPlayingTime"] = minTime
            data["maxPlayingTime"] = maxTime
        }
        let players = try UserRepository().players(for: game)
        return [
            "id": id,
            "data": data,
            "host": [
                "name": game.host.name,
                "picture": game.host.picture?.absoluteString ?? Settings.defaultProfilePicture
            ],
            "date": formatted(game.date, dateStyle: .long),
            "players": players.map { ["picture": $0.picture?.absoluteString ?? Settings.defaultProfilePicture ] },
            "availableSeats": availableSeats,
            "distance": Int(ceil(distance / 1000))
        ]
    }
}
