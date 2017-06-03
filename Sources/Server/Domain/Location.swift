struct Location {
    
    let address: String
    let latitude: Double
    let longitude: Double
    
    var distance: Double? // Calculated when a user searches for games. Not persisted.
    
    init(address: String, latitude: Double, longitude: Double, distance: Double? = nil) {
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
    }
}

// MARK: - BSON

import BSON
import GeoJSON

extension Location {
    
    init(bson: Document) throws {
        guard let address = String(bson["address"]) else {
            try logAndThrow(BSONError.missingField(name: "address"))
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
                  latitude: latitude,
                  longitude: longitude,
                  distance: distance)
    }
    
    func toBSON() -> Document {
        return [
            "address": address,
            "coordinates": Point(coordinate: Position(first: longitude, second: latitude))
        ]
    }
}
