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
        return [
            "id": game.id,
            "name": game.name,
            "year": game.yearPublished,
            "minPlayerCount": game.playerCount.lowerBound,
            "maxPlayerCount": game.playerCount.upperBound,
            "minPlayingTime": game.playingTime.lowerBound,
            "maxPlayingTime": game.playingTime.upperBound,
            "picture": game.thumbnail?.absoluteString ?? Settings.defaultGameThumbnail
        ]
    }
}
