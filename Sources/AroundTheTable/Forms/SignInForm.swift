/**
 Form submitted when signing in using email credentials.
 */
struct SignInForm: Codable {
    
    let email: String
    let password: String
}
