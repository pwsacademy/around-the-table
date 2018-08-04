/**
 Form submitted when signing up using email credentials.
 */
struct SignUpForm: Codable {
    
    let email: String
    let password: String
    let name: String
}
