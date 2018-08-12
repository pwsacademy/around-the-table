/**
 View model for **host-game-selection.stencil**.
 */
struct HostGameSelectionViewModel: Codable {
    
    let base: BaseViewModel
    
    struct GameViewModel: Codable {
        
        let id: Int
        let name: String
        let yearPublished: Int
        let playerCount: CountableClosedRange<Int>
        let playingTime: CountableClosedRange<Int>
        let picture: String
        
        init(_ game: Game) {
            self.id = game.id
            self.name = game.name
            self.yearPublished = game.yearPublished
            self.playerCount = game.playerCount
            self.playingTime = game.playingTime
            self.picture = game.thumbnail?.absoluteString ?? Settings.defaultGameThumbnail
        }
    }
    
    let results: [GameViewModel]
    
    init(base: BaseViewModel, results: [Game]) {
        self.base = base
        self.results = results.map(GameViewModel.init)
    }
}
