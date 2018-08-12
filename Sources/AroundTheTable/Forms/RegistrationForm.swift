/**
 Form for submitting a registration.
 */
struct RegistrationFrom: Codable {
    
    /// The number of seats requested.
    let seats: Int
    
    var isValid: Bool {
        return seats >= 1
    }
}
