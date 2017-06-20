import Foundation

/*
 View context for `game.stencil`.
 */
struct GameViewContext: ViewContext {
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], user: User, game: Game, requests: [Request]) throws {
        guard let id = game.id,
              let distance = game.location.distance,
              let availableSeats = game.availableSeats else {
            try logAndThrow(ServerError.invalidState)
        }
        self.base = base
        contents = [
            "id": id,
            "data": try gameDataMapper(game.data),
            "host": [
                "id": game.host.id,
                "name": game.host.name,
                "picture": game.host.picture?.absoluteString ?? Settings.defaultProfilePicture
            ],
            "location": [
                "address": game.location.address,
                "latitude": game.location.latitude,
                "longitude": game.location.longitude,
                "distance": Int(ceil(distance / 1000))
            ],
            "date": formatted(game.date, dateStyle: .long, timeStyle: .none),
            "time": formatted(game.date, dateStyle: .none, timeStyle: .short),
            "prereservedSeats": game.prereservedSeats,
            "availableSeats": availableSeats,
            "approvedRequests": try requests.filter { $0.approved }.map { try requestMapper($0) },
            "requests": try requests.filter { !$0.approved }.map { try requestMapper($0).appending(["willCauseOverbooking": $0.seats > availableSeats]) },
            "userIsPlayer": requests.filter { $0.approved }.contains { $0.player == user },
            "userIsHost": game.host == user,
            "userHasRequested": requests.contains { $0.player == user }
        ]
        if availableSeats > 0 {
            contents["seatOptions"] = Array(1...availableSeats)
        }
    }
    
    func gameDataMapper(_ data: GameData) throws -> [String: Any] {
        return [
            "id": data.id,
            "name": data.name,
            "playerCount": data.playerCount.upperBound,
            "minPlayingTime": data.playingTime.lowerBound,
            "maxPlayingTime": data.playingTime.upperBound,
            "picture": data.picture?.absoluteString ?? Settings.defaultGamePicture
        ]
    }
    
    func requestMapper(_ request: Request) throws -> [String: Any] {
        guard let id = request.id else {
            try logAndThrow(ServerError.invalidState)
        }
        return [
            "id": id,
            "player": [
                "id": request.player.id,
                "name": request.player.name,
                "picture": request.player.picture?.absoluteString ?? Settings.defaultProfilePicture
            ],
            "seats": request.seats
        ]
    }
}
