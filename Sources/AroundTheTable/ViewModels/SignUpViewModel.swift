/**
 View model for **signup-email.stencil**.
 */
struct SignUpViewModel: Codable {
    
    let base: BaseViewModel
    let name: String
    let email: String
    let error: Bool
}
