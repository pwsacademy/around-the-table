import Foundation

/*
 Most of this data is gathered from Facebook during sign-up.
 */
final class User {
    
    let id: String // Facebook ID.
    var name: String
    var picture: URL?
    var location: Location?
    
    init(id: String, name: String, picture: URL? = nil, location: Location? = nil) {
        self.id = id
        self.name = name
        self.picture = picture
        self.location = location
    }
}

extension User: Equatable {
    
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - BSON

import BSON

extension User {
    
    convenience init(bson: Document) throws {
        guard let id = String(bson["_id"]) else {
            try logAndThrow(BSONError.missingField(name: "_id"))
        }
        guard let name = String(bson["name"]) else {
            try logAndThrow(BSONError.missingField(name: "name"))
        }
        let picture = String(bson["picture"])
        let location = Document(bson["location"])
        self.init(id: id,
                  name: name,
                  picture: picture != nil ? URL(string: picture!) : nil,
                  location: location != nil ? try Location(bson: location!) : nil)
    }
    
    func toBSON() -> Document {
        var bson: Document = [
            "_id": id,
            "name": name,
        ]
        if let picture = picture {
            bson["picture"] = picture.absoluteString
        }
        if let location = location {
            bson["location"] = location.toBSON()
        }
        return bson
    }
}
