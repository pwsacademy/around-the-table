import Foundation

/*
 View context for `game.stencil`.
 */
struct GameViewContext: ViewContext {
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], user: User?, game: Game, requests: [Request]) throws {
        guard let id = game.id,
              let distance = game.location.distance else {
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
                "city": game.location.city,
                "latitude": game.location.latitude,
                "longitude": game.location.longitude,
                "distance": Int(ceil(distance / 1000))
            ],
            "info": game.info,
            "date": game.date.formatted(dateStyle: .full),
            "time": game.date.formatted(timeStyle: .short),
            "isOver": game.date.compare(Date()) == .orderedAscending,
            "deadlineDate": game.deadline.formatted(dateStyle: .full),
            "deadlineTime": game.deadline.formatted(timeStyle: .short),
            "deadlineHasPassed": game.deadline.compare(Date()) == .orderedAscending,
            "prereservedSeats": game.prereservedSeats,
            "availableSeats": game.availableSeats,
            "minPlayerCountIsReached": game.data.playerCount.upperBound - game.availableSeats >= game.data.playerCount.lowerBound,
            "approvedRequests": try requests.filter { $0.approved }.map { try requestMapper($0) },
            "requests": try requests.filter { !$0.approved }.map { try requestMapper($0).appending(["willCauseOverbooking": $0.seats > game.availableSeats]) },
            "userIsPlayer": requests.filter { $0.approved }.contains { $0.player == user },
            "userIsHost": game.host == user,
            "userHasRequested": requests.contains { $0.player == user },
            "isCancelled": game.cancelled
        ]
        if game.availableSeats > 0 {
            contents["seatOptions"] = Array(1...game.availableSeats)
        } else {
            contents["seatOptions"] = Array(1...game.data.playerCount.upperBound)
        }
    }
    
    func gameDataMapper(_ data: GameData) throws -> [String: Any] {
        return [
            "id": data.id,
            "name": data.name,
            "minPlayerCount": data.playerCount.lowerBound,
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
