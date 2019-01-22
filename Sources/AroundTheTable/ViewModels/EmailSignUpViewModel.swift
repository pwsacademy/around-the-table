import HTMLEntities

/**
 View model for **signup-email.stencil**.
 */
struct EmailSignUpViewModel: Codable {
    
    let base: BaseViewModel
    let name: String
    let email: String
    let error: Bool
    
    init(base: BaseViewModel, name: String, email: String, error: Bool) {
        self.base = base
        self.name = name.htmlEscape()
        self.email = email.htmlEscape()
        self.error = error
    }
}
