import BSON
import Foundation

/**
 Adds `BSON.Primitive` conformance to `ClosedRange`.
 */
extension ClosedRange: Primitive where Bound: Primitive {
    
    /// A `ClosedRange` is stored as a BSON `Document`.
    public var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `ClosedRange` as a BSON `Document`.
    var document: Document {
        return [
            "lowerBound": lowerBound,
            "upperBound": upperBound
        ]
    }
    
    /**
     Returns this `ClosedRange` as a BSON `Document` in binary form.
     */
    public func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes a `ClosedRange` from a BSON primitive.
     
     - Returns: `nil` when the primitive is not a `Document`.
     - Throws: a `BSONError` when the document does not contain all required properties.
     */
    init?(_ bson: Primitive?) throws {
        guard let bson = bson as? Document else {
            return nil
        }
        guard let lowerBound = bson["lowerBound"] as? Bound else {
            throw log(BSONError.missingField(name: "lowerBound"))
        }
        guard let upperBound = bson["upperBound"] as? Bound else {
            throw log(BSONError.missingField(name: "upperBound"))
        }
        self = lowerBound...upperBound
    }
}

/**
 Adds `BSON.Primitive` conformance to `URL`.
 */
extension URL: Primitive {
    
    /// A `URL` is stored as a string.
    public var typeIdentifier: Byte {
        return absoluteString.typeIdentifier
    }
    
    /**
     Returns this `URL` as a string in binary form.
     */
    public func makeBinary() -> Bytes {
        return absoluteString.makeBinary()
    }
    
    /**
     Decodes a `URL` from a BSON primitive.
     
     - Returns: `nil` when the primitive is not a string.
     */
    init?(_ bson: Primitive?) throws {
        guard let absoluteString = String(bson) else {
            return nil
        }
        self.init(string: absoluteString)
    }
}
