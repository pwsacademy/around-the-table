import BSON
import Foundation

/**
 A user.
 
 Currently we only support signing up through Facebook.
 As such, most of a user's properties are pulled from his/her Facebook profile.
 */
final class User {
    
    /// The user's Facebook ID.
    let id: String
    
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
     
     Only `id` and `name` are required parameters.
     `lastSignIn` is set to the current date and time.
     */
    init(id: String, name: String, picture: URL? = nil, location: Location? = nil) {
        self.id = id
        self.name = name
        self.picture = picture
        self.location = location
        lastSignIn = Date()
    }
    
    /**
     Full initializer, only used when decoding from BSON.
     */
    init(id: String, name: String, picture: URL?, location: Location?, lastSignIn: Date) {
        self.id = id
        self.name = name
        self.picture = picture
        self.location = location
        self.lastSignIn = lastSignIn
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
        guard let id = String(bson["_id"]) else {
            throw log(BSONError.missingField(name: "_id"))
        }
        guard let name = String(bson["name"]) else {
            throw log(BSONError.missingField(name: "name"))
        }
        guard let lastSignIn = Date(bson["lastSignIn"]) else {
            throw log(BSONError.missingField(name: "lastSignIn"))
        }
        let picture = try URL(bson["picture"])
        let location = try Location(bson["location"])
        self.init(id: id,
                  name: name,
                  picture: picture,
                  location: location,
                  lastSignIn: lastSignIn)
    }
}

