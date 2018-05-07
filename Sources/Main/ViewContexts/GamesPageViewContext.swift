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
