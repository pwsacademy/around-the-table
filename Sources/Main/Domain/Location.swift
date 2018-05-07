struct Location {
    
    let address: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    
    /*
     Distance to the current user.
     Calculated when a user searches for games. Not persisted.
     */
    var distance: Double?
    
    init(address: String = "", city: String = "", country: String = "", latitude: Double, longitude: Double, distance: Double? = nil) {
        self.address = address
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
    }
    
    static let `default` = Location(latitude: Settings.defaultCoordinates.latitude, longitude: Settings.defaultCoordinates.longitude)
}

// MARK: - BSON

import BSON
import GeoJSON

extension Location {
    
    init(bson: Document) throws {
        guard let address = String(bson["address"]) else {
            try logAndThrow(BSONError.missingField(name: "address"))
        }
        guard let city = String(bson["city"]) else {
            try logAndThrow(BSONError.missingField(name: "city"))
        }
        guard let country = String(bson["country"]) else {
            try logAndThrow(BSONError.missingField(name: "country"))
        }
        guard let coordinates = Array(bson["coordinates"]["coordinates"]) else {
            try logAndThrow(BSONError.missingField(name: "coordinates"))
        }
        guard let latitude = Double(coordinates[1]) else {
            try logAndThrow(BSONError.missingField(name: "latitude"))
        }
        guard let longitude = Double(coordinates[0]) else {
            try logAndThrow(BSONError.missingField(name: "longitude"))
        }
        /*
         Even though `distance` is not persisted, we need to check for its presence.
         It may be added to the document by the database during a query.
         */
        let distance = Double(bson["distance"])
        self.init(address: address,
                  city: city,
                  country: country,
                  latitude: latitude,
                  longitude: longitude,
                  distance: distance)
    }
    
    func toBSON() -> Document {
        return [
            "address": address,
            "city": city,
            "country": country,
            "coordinates": Point(coordinate: Position(first: longitude, second: latitude))
        ]
    }
}
