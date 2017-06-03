import Foundation

/*
 View context for `host-game-select.stencil`.
 */
struct HostGameSelectViewContext: ViewContext {
    
    let base: [String: Any]
    var contents: [String: Any] = [:]
    
    init(base: [String: Any], results: [GameData]) {
        self.base = base
        contents = [
            "results": results.sorted { $0.yearPublished > $1.yearPublished }.map(gameDataMapper)
        ]
    }
    
    private func gameDataMapper(_ game: GameData) -> [String: Any] {
        var output: [String: Any] = [
            "id": game.id,
            "name": game.name,
            "year": game.yearPublished,
            "picture": game.thumbnail?.absoluteString ?? Settings.defaultGameThumbnail
        ]
        switch game.playerCount {
        case .fixed(amount: let amount):
            output["playerCount"] = amount
        case .range(min: let min, max: let max):
            output["minPlayerCount"] = min
            output["maxPlayerCount"] = max
        }
        switch game.playingTime {
        case .average(time: let time):
            output["playingTime"] = time
        case .range(min: let min, max: let max):
            output["minPlayingTime"] = min
            output["maxPlayingTime"] = max
        }
        return output
    }
}
