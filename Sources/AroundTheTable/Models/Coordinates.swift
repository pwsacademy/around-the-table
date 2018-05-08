import BSON
import GeoJSON

/**
 A pair of coordinates describing a geographic point.
 */
struct Coordinates: Equatable, Codable {
    
    /// The latitude of this geographic point.
    let latitude: Double
    
    /// The longitude of this geographic point.
    let longitude: Double
    
    /// The default coordinates configured in the app's settings.
    static let `default` = Coordinates(latitude: Settings.defaultCoordinates.latitude, longitude: Settings.defaultCoordinates.longitude)
}

/**
 Adds `BSON.Primitive` conformance to `Coordinates`.
 */
extension Coordinates: Primitive {
    
    /**
     Returns these `Coordinates` as a GeoJSON `Point`.
     */
    var point: Point {
        return Point(coordinate: Position(first: longitude, second: latitude))
    }
    
    /**
     `Coordinates` are stored as a GeoJSON `Point` (which is a `Document`).
     */
    var typeIdentifier: Byte {
        return point.makePrimitive().typeIdentifier
    }
    
    /**
     Returns these `Coordinates` as a GeoJSON `Point` in binary form.
     */
    func makeBinary() -> Bytes {
        return point.makePrimitive().makeBinary()
    }
    
    /**
     Decodes `Coordinates` from a BSON primitive.
     
     - Returns: `nil` when the primitive is not a `Document`.
     - Throws: a `BSONError` when the document does not contain all required properties.
     */
    init?(_ bson: Primitive?) throws {
        guard let bson = bson as? Document else {
            return nil
        }
        guard let coordinates = Array(bson["coordinates"]) else {
            throw log(BSONError.missingField(name: "coordinates"))
        }
        guard coordinates.count == 2,
              let latitude = Double(coordinates[1]),
              let longitude = Double(coordinates[0]) else {
            throw log(BSONError.invalidField(name: "coordinates"))
        }
        self.init(latitude: latitude, longitude: longitude)
    }
}
