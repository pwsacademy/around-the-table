import Foundation

/*
 View context for `games-page.stencil`.
 */
struct GamesPageViewContext: ViewContext {
    
    enum PageType: String {
        
        case newest = "newest-games"
        case upcoming = "upcoming-games"
        case nearMe = "games-near-me"
    }
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], type: PageType, games: [Game], page: Int, hasNextPage: Bool) throws {
        self.base = base
        contents = [
            "type": type.rawValue,
            "games": try games.map(gameMapper),
        ]
        if page > 0 {
            contents["previousPage"] = "/web/\(type.rawValue)?page=\(page - 1)"
        }
        if hasNextPage {
            contents["nextPage"] = "/web/\(type.rawValue)?page=\(page + 1)"
        }
    }
    
    private func gameMapper(_ game: Game) throws -> [String: Any] {
        guard let id = game.id,
              let distance = game.location.distance,
              let seats = game.availableSeats,
              case .fixed(let amount) = game.data.playerCount else {
            try logAndThrow(ServerError.invalidState)
        }
        var data: [String: Any] = [
            "name": game.data.name,
            "playerCount": amount,
            "picture": game.data.picture?.absoluteString ?? Settings.defaultGamePicture,
        ]
        switch game.data.playingTime {
        case .average(time: let time):
            data["playingTime"] = time
        case .range(min: let minTime, max: let maxTime):
            data["minPlayingTime"] = minTime
            data["maxPlayingTime"] = maxTime
        }
        return [
            "id": id,
            "data": data,
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
