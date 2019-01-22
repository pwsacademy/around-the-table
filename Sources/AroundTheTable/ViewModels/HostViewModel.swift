import HTMLEntities

/**
 View model for **host.stencil**.
 */
struct HostViewModel: Codable {
    
    let base: BaseViewModel
    let query: String
    let error: Bool
    
    init(base: BaseViewModel, query: String, error: Bool) {
        self.base = base
        self.query = query.htmlEscape()
        self.error = error
    }
}
