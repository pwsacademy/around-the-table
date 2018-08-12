/**
 Form for editing an activity's address.
 */
struct EditActivityAddressForm: Codable {
    
    let address: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double

    var location: Location {
        return Location(coordinates: Coordinates(latitude: latitude, longitude: longitude),
                        address: address, city: city, country: country)
    }
    
    // TODO: This can be improved using count(where:) once that's added to the Standard Library.
    var isValid: Bool {
        return ![address, city, country].map({ $0.isEmpty }).contains(true)
    }
}
