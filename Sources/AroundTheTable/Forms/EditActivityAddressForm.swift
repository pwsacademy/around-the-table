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
    
    var isValid: Bool {
        return ![address, city, country].contains { $0.isEmpty }
    }
}
