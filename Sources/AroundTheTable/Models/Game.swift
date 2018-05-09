import BSON
import Foundation
import LoggerAPI

/**
 A game.
 
 This data is gathered from BoardGameGeek.
 */
class Game {
    
    /// The game's ID on BGG.
    let id: Int
    
    /// The date and time at which this data was fetched from BGG.
    /// This is used for cache management.
    let creationDate: Date
    
    /// The game's primary name.
    let name: String
    
    /// All known names for the game, primary and alternate.
    let names: [String]
    
    /// The year in which the game was published.
    let yearPublished: Int
    
    /// The player counts the game supports.
    let playerCount: CountableClosedRange<Int>
    
    /// An estimate of the duration of play.
    let playingTime: CountableClosedRange<Int>
    
    /// A link to a representative image for the game.
    /// If this is `nil`, a default image will be used.
    let picture: URL?
    
    /// A thumbnail version of the representative image.
    /// If this is `nil`, a default image will be used.
    let thumbnail: URL?
    
    /**
     Initializes a `Game`.
     
     `creationDate` is set to the current date and time.
     */
    init(id: Int,
         name: String, names: [String],
         yearPublished: Int,
         playerCount: CountableClosedRange<Int>,
         playingTime: CountableClosedRange<Int>,
         picture: URL?, thumbnail: URL?) {
        self.id = id
        creationDate = Date()
        self.name = name
        self.names = names
        self.yearPublished = yearPublished
        self.playerCount = playerCount
        self.playingTime = playingTime
        self.picture = picture
        self.thumbnail = thumbnail
    }
    
    /**
     Full initializer, only used when decoding from BSON.
     */
    init(id: Int,
         creationDate: Date,
         name: String, names: [String],
         yearPublished: Int,
         playerCount: CountableClosedRange<Int>,
         playingTime: CountableClosedRange<Int>,
         picture: URL?, thumbnail: URL?) {
        self.id = id
        self.creationDate = creationDate
        self.name = name
        self.names = names
        self.yearPublished = yearPublished
        self.playerCount = playerCount
        self.playingTime = playingTime
        self.picture = picture
        self.thumbnail = thumbnail
    }
}

extension Game {
    
    /**
     Decodes a `Game` from XML returned by the BGG XMP API.
     
     Example: https://boardgamegeek.com/xmlapi2/thing?id=45
     */
    convenience init(xml: XMLNode) throws {
        guard let idString = try xml.nodes(forXPath: "@id").first?.stringValue,
              let id = Int(idString) else {
            throw log(GeekError.missingElement(name: "id", id: 0))
        }
        guard let name = try xml.nodes(forXPath: "name[@type='primary']/@value").first?.stringValue else {
            throw log(GeekError.missingElement(name: "name", id: id))
        }
        let names = try xml.nodes(forXPath: "name/@value").compactMap { $0.stringValue }
        guard let yearString = try xml.nodes(forXPath: "yearpublished/@value").first?.stringValue,
              let yearPublished = Int(yearString), yearPublished != 0 else {
            throw log(GeekError.missingElement(name: "yearpublished", id: id))
        }
        guard let minPlayerCountString = try xml.nodes(forXPath: "minplayers/@value").first?.stringValue,
              let minPlayerCount = Int(minPlayerCountString) else {
            throw log(GeekError.missingElement(name: "minplayers", id: id))
        }
        guard let maxPlayerCountString = try xml.nodes(forXPath: "maxplayers/@value").first?.stringValue,
              let maxPlayerCount = Int(maxPlayerCountString) else {
            throw log(GeekError.missingElement(name: "maxplayers", id: id))
        }
        // Make sure `playerCount` is a valid range.
        let playerCount: CountableClosedRange<Int>
        switch (minPlayerCount, maxPlayerCount) {
        case let (min, max) where min <= 0 && max <= 0:
            throw log(GeekError.invalidElement(name: "minplayers/maxplayers", id: id))
        case (let amount, 0), (0, let amount):
            Log.warning("BGG warning: player count for #\(id) contains 0.")
            playerCount = amount...amount
        case let (min, max) where min > max:
            Log.warning("BGG warning: player count for #\(id) has min > max.")
            playerCount = max...min
        case let (min, max):
            playerCount = min...max
        }
        guard let minPlayingTimeString = try xml.nodes(forXPath: "minplaytime/@value").first?.stringValue,
              let minPlayingTime = Int(minPlayingTimeString) else {
            throw log(GeekError.missingElement(name: "minplaytime", id: id))
        }
        guard let maxPlayingTimeString = try xml.nodes(forXPath: "maxplaytime/@value").first?.stringValue,
              let maxPlayingTime = Int(maxPlayingTimeString) else {
            throw log(GeekError.missingElement(name: "maxplaytime", id: id))
        }
        // Make sure `playingTime` is a valid range.
        let playingTime: CountableClosedRange<Int>
        switch (minPlayingTime, maxPlayingTime) {
        case let (min, max) where min <= 0 && max <= 0:
            throw log(GeekError.invalidElement(name: "minplaytime/maxplaytime", id: id))
        case (let time, 0), (0, let time):
            Log.warning("BGG warning: playing time for #\(id) contains 0.")
            playingTime = time...time
        case let (min, max) where min > max:
            Log.warning("BGG warning: playing time for #\(id) has min > max.")
            playingTime = max...min
        case let (min, max):
            playingTime = min...max
        }
        let picture: URL? = try {
            guard let url = try xml.nodes(forXPath: "image").first?.stringValue else {
                return nil
            }
            return URL(string: url.hasPrefix("//") ? "https:" + url : url)
        }()
        let thumbnail: URL? = try {
            guard let url = try xml.nodes(forXPath: "thumbnail").first?.stringValue else {
                return nil
            }
            return URL(string: url.hasPrefix("//") ? "https:" + url : url)
        }()
        self.init(id: id,
                  name: name, names: names,
                  yearPublished: yearPublished,
                  playerCount: playerCount,
                  playingTime: playingTime,
                  picture: picture, thumbnail: thumbnail)
    }
}

/**
 Adds `BSON.Primitive` conformance to `Game`.
 */
extension Game: Primitive {
    
    /// A `Game` is stored as a BSON `Document`.
    var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `Game` as a BSON `Document`.
    /// Optional properties are included only when they are not `nil`.
    var document: Document {
        var document: Document = [
            "_id": id,
            "creationDate": creationDate,
            "name": name,
            "names": names,
            "yearPublished": yearPublished,
            "playerCount": playerCount,
            "playingTime": playingTime
        ]
        if let picture = picture {
            document["picture"] = picture
        }
        if let thumbnail = thumbnail {
            document["thumbnail"] = thumbnail
        }
        return document
    }
    
    /**
     Returns this `Game` as a BSON `Document` in binary form.
     */
    func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes a `Game` from a BSON primitive.
     
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
        guard let creationDate = Date(bson["creationDate"]) else {
            throw log(BSONError.missingField(name: "creationDate"))
        }
        guard let name = String(bson["name"]) else {
            throw log(BSONError.missingField(name: "name"))
        }
        guard let names = Array(bson["names"])?.compactMap({ String($0) }) else {
            throw log(BSONError.missingField(name: "names"))
        }
        guard let yearPublished = Int(bson["yearPublished"]) else {
            throw log(BSONError.missingField(name: "yearPublished"))
        }
        guard let playerCount = try CountableClosedRange<Int>(bson["playerCount"]) else {
            throw log(BSONError.missingField(name: "playerCount"))
        }
        guard let playingTime = try CountableClosedRange<Int>(bson["playingTime"]) else {
            throw log(BSONError.missingField(name: "playingTime.min"))
        }
        let picture = try URL(bson["picture"])
        let thumbnail = try URL(bson["thumbnail"])
        self.init(id: id,
                  creationDate: creationDate,
                  name: name,
                  names: names,
                  yearPublished: yearPublished,
                  playerCount: playerCount,
                  playingTime: playingTime,
                  picture: picture,
                  thumbnail: thumbnail)
    }
}
