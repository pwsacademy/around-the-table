import BSON
import Foundation

/**
 A user.
 */
final class User {
    
    /// The user's ID.
    /// If set to nil, an ID is assigned when the instance is persisted.
    var id: Int?
    
    /// The user's display name.
    var name: String
    
    /// The user's profile picture.
    /// A default picture will be used when this value is `nil`.
    var picture: URL?
    
    /// The user's stored location.
    var location: Location?
    
    /// The date and time of the user's last sign-in.
    var lastSignIn: Date
    
    /**
     Initializes a `User`.
     
     `id` should be set to nil for new (unpersisted) instances. This is also its default value.
     `lastSignIn` is set to the current date and time by default.
     `picture` and `location` are nil by default.
     */
    init(id: Int? = nil, lastSignIn: Date = Date(), name: String, picture: URL? = nil, location: Location? = nil) {
        self.id = id
        self.lastSignIn = lastSignIn
        self.name = name
        self.picture = picture
        self.location = location
    }
}

/**
 Adds `Equatable` conformance to `User`.
 
 Users are considered equal if they have the same `id`.
 */
extension User: Equatable {
    
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

/**
 Adds `BSON.Primitive` conformance to `User`.
 */
extension User: Primitive {
    
    /// A `User` is stored as a BSON `Document`.
    var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `User` as a BSON `Document`.
    /// Optional properties are included only when they are not `nil`.
    var document: Document {
        var document: Document = [
            "_id": id,
            "name": name,
            "lastSignIn": lastSignIn
        ]
        if let picture = picture {
            document["picture"] = picture
        }
        if let location = location {
            document["location"] = location
        }
        return document
    }
    
    /**
     Returns this `User` as a BSON `Document` in binary form.
     */
    func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes a `User` from a BSON primitive.
     
     - Returns: `nil` when the primitive is not a `Document`.
     - Throws: a `BSONError` when the document does not contain all required properties.
     */
    convenience init?(_ bson: Primitive?) throws {
        guard let bson = bson as? Document else {
            return nil
        }
        guard let id = Int(bson["_id"]) else {
            throw log(BSONError.missingField(name: "_id"))
        }
        guard let lastSignIn = Date(bson["lastSignIn"]) else {
            throw log(BSONError.missingField(name: "lastSignIn"))
        }
        guard let name = String(bson["name"]) else {
            throw log(BSONError.missingField(name: "name"))
        }
        let picture = try URL(bson["picture"])
        let location = try Location(bson["location"])
        self.init(id: id,
                  lastSignIn: lastSignIn,
                  name: name,
                  picture: picture,
                  location: location)
    }
}

