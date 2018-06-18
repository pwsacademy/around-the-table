import BSON

/**
 The location of a user or activity.
 */
struct Location: Equatable, Codable {
    
    /// The coordinates for this location.
    let coordinates: Coordinates
    
    /// The address that corresponds with this location.
    let address: String
    
    /// The city in which this location is located.
    let city: String
    
    /// The country in which this location is located.
    let country: String
}

/**
 Adds `BSON.Primitive` conformance to `Location`.
 */
extension Location: Primitive {
    
    /// A `Location` is stored as a BSON `Document`.
    var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `Location` as a BSON `Document`.
    var document: Document {
        return [
            "coordinates": coordinates,
            "address": address,
            "city": city,
            "country": country
        ]
    }
    
    /**
     Returns this `Location` as a BSON `Document` in binary form.
     */
    func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes a `Location` from a BSON primitive.
     
     - Returns: `nil` when the primitive is not a `Document`.
     - Throws: a `BSONError` when the document does not contain all required properties.
     */
    init?(_ bson: Primitive?) throws {
        guard let bson = bson as? Document else {
            return nil
        }
        guard let coordinates = try Coordinates(bson["coordinates"]) else {
            throw log(BSONError.missingField(name: "coordinates"))
        }
        guard let address = String(bson["address"]) else {
            throw log(BSONError.missingField(name: "address"))
        }
        guard let city = String(bson["city"]) else {
            throw log(BSONError.missingField(name: "city"))
        }
        guard let country = String(bson["country"]) else {
            throw log(BSONError.missingField(name: "country"))
        }
        self.init(coordinates: coordinates,
                  address: address,
                  city: city,
                  country: country)
    }
}
