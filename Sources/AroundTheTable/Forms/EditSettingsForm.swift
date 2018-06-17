/**
 Form submitted to edit the user's settings.
 */
struct EditSettingsForm: Codable {
    
    let address: String?
    let city: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    
    var location: Location? {
        guard let address = address, let city = city, let country = country,
              let latitude = latitude, let longitude = longitude else {
            return nil
        }
        return Location(coordinates: Coordinates(latitude: latitude, longitude: longitude),
                        address: address, city: city, country: country)
    }
}
