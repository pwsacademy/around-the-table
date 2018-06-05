/**
 View model for **host.stencil**.
 */
struct HostViewModel: Codable {
    
    let base: BaseViewModel
    let query: String
    let error: Bool
}
