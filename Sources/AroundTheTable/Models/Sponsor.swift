import BSON
import Foundation

/**
 A sponsor.
 */
final class Sponsor {
    
    /// A unique code for the sponsor.
    let code: String
    
    /// The sponsor's display name.
    var name: String
    
    /// The sponsor's description.
    /// This can be several paragraphs of text.
    var description: String
    
    /// The sponsor's profile picture.
    var picture: URL
    
    /// A link to the sponsor's website.
    var link: URL
    
    /// The weight of the sponsor.
    /// This must be >= 1 and determines how often the sponsor is shown.
    /// A sponsor is shown on s/t percent of page requests, where s is the sponsor's weight
    /// and t is the total combined weight of all sponsors.
    var weight: Int
    
    /**
     Initializes a `Sponsor`.
     */
    init(code: String, name: String, description: String, picture: URL, link: URL, weight: Int) {
        self.code = code
        self.name = name
        self.description = description
        self.picture = picture
        self.link = link
        self.weight = weight
    }
}

/**
 Adds `Equatable` conformance to `Sponsor`.
 
 Sponsors are considered equal if they have the same `code`.
 */
extension Sponsor: Equatable {
    
    static func ==(lhs: Sponsor, rhs: Sponsor) -> Bool {
        return lhs.code == rhs.code
    }
}

/**
 Adds `BSON.Primitive` conformance to `Sponsor`.
 
 Note that `weight` is not stored.
 To learn how a sponsor's weight is implemented, see **SponsorRepository.swift**.
 */
extension Sponsor: Primitive {
    
    /// A `Sponsor` is stored as a BSON `Document`.
    var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `Sponsor` as a BSON `Document`.
    var document: Document {
        return [
            "code": code,
            "name": name,
            "description": description,
            "picture": picture,
            "link": link
        ]
    }
    
    /**
     Returns this `Sponsor` as a BSON `Document` in binary form.
     */
    func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes a `Sponsor` from a BSON primitive.
     
     - Throws: a `BSONError` when the document does not contain all required properties.
     */
    convenience init?(_ bson: Primitive?) throws {
        guard let bson = bson as? Document else {
            return nil
        }
        guard let code = String(bson["code"]) else {
            throw log(BSONError.missingField(name: "code"))
        }
        guard let name = String(bson["name"]) else {
            throw log(BSONError.missingField(name: "name"))
        }
        guard let description = String(bson["description"]) else {
            throw log(BSONError.missingField(name: "description"))
        }
        guard let picture = try URL(bson["picture"]) else {
            throw log(BSONError.missingField(name: "picture"))
        }
        guard let link = try URL(bson["link"]) else {
            throw log(BSONError.missingField(name: "link"))
        }
        guard let weight = Int(bson["weight"]) else {
            throw log(BSONError.missingField(name: "weight"))
        }
        self.init(code: code,
                  name: name,
                  description: description,
                  picture: picture,
                  link: link,
                  weight: weight)
    }
}
