import Foundation
import LoggerAPI

/*
 Game data gathered from BoardGameGeek.
 */
struct GameData {
    
    let id: Int // BoardGameGeek ID.
    var name: String // Primary name. Replaced by the name selected by the user when hosting a game.
    var names: [String]? // All known names, primary and alternate. Can be removed once the user has selected a name to display.
    let yearPublished: Int
    var playerCount: CountableClosedRange<Int> // Possible player counts. Replaced by the player count selected by the user when hosting a game.
    let playingTime: CountableClosedRange<Int>
    let picture: URL?
    let thumbnail: URL?
}

// MARK: - XML

extension GameData {
    
    /*
     Parsed from BoardGameGeek.
     Example XML: https://boardgamegeek.com/xmlapi2/thing?id=45
     */
    init(xml: XMLNode) throws {
        guard let idString = try xml.nodes(forXPath: "@id").first?.stringValue,
              let id = Int(idString) else {
            try logAndThrow(BoardGameGeekError.missingElement(name: "id", id: 0))
        }
        guard let name = try xml.nodes(forXPath: "name[@type='primary']/@value").first?.stringValue else {
            try logAndThrow(BoardGameGeekError.missingElement(name: "name", id: id))
        }
        let names = try xml.nodes(forXPath: "name/@value").flatMap { $0.stringValue }
        guard let yearString = try xml.nodes(forXPath: "yearpublished/@value").first?.stringValue,
              let yearPublished = Int(yearString), yearPublished != 0 else {
            try logAndThrow(BoardGameGeekError.missingElement(name: "yearpublished", id: id))
        }
        guard let minPlayerCountString = try xml.nodes(forXPath: "minplayers/@value").first?.stringValue,
              let minPlayerCount = Int(minPlayerCountString) else {
            try logAndThrow(BoardGameGeekError.missingElement(name: "minplayers", id: id))
        }
        guard let maxPlayerCountString = try xml.nodes(forXPath: "maxplayers/@value").first?.stringValue,
              let maxPlayerCount = Int(maxPlayerCountString) else {
            try logAndThrow(BoardGameGeekError.missingElement(name: "maxplayers", id: id))
        }
        let playerCount: CountableClosedRange<Int> = try {
            switch (minPlayerCount, maxPlayerCount) {
            case let (min, max) where min <= 0 && max <= 0:
                try logAndThrow(BoardGameGeekError.invalidElement(name: "minplayers/maxplayers", id: id))
            case (let amount, 0), (0, let amount):
                return amount...amount
            case let (min, max) where min > max:
                return max...min
            case let (min, max):
                return min...max
            }
        }()
        guard let minPlayingTimeString = try xml.nodes(forXPath: "minplaytime/@value").first?.stringValue,
              let minPlayingTime = Int(minPlayingTimeString) else {
            try logAndThrow(BoardGameGeekError.missingElement(name: "minplaytime", id: id))
        }
        guard let maxPlayingTimeString = try xml.nodes(forXPath: "maxplaytime/@value").first?.stringValue,
              let maxPlayingTime = Int(maxPlayingTimeString) else {
            try logAndThrow(BoardGameGeekError.missingElement(name: "maxplaytime", id: id))
        }
        let playingTime: CountableClosedRange<Int> = try {
            switch (minPlayingTime, maxPlayingTime) {
            case let (min, max) where min <= 0 && max <= 0:
                try logAndThrow(BoardGameGeekError.invalidElement(name: "minplaytime/maxplaytime", id: id))
            case (let time, 0), (0, let time):
                return time...time
            case let (min, max) where min > max:
                return max...min
            case let (min, max):
                return min...max
            }
        }()
        let picture: URL? = try {
            guard let urlString = try xml.nodes(forXPath: "image").first?.stringValue else {
                return nil
            }
            let urlComponents = urlString.components(separatedBy: "/")
            guard urlComponents.count > 1,
                  let file = urlComponents.last,
                  let period = file.index(of: ".") else {
                Log.warning("Failed to generate picture URL for #\(id)")
                return nil
            }
            let fileName = file[..<period]
            let fileExtension = file[period...]
            let newURLString = "https://cf.geekdo-images.com/images/\(fileName)_md\(fileExtension)"
            return URL(string: newURLString)
        }()
        let thumbnail: URL? = try {
            guard let urlString = try xml.nodes(forXPath: "thumbnail").first?.stringValue else {
                return nil
            }
            return URL(string: urlString.hasPrefix("//") ? "https:" + urlString : urlString)
        }()
        self.init(id: id,
                  name: name,
                  names: names,
                  yearPublished: yearPublished,
                  playerCount: playerCount,
                  playingTime: playingTime,
                  picture: picture,
                  thumbnail: thumbnail)
    }
}

// MARK: - BSON

import BSON

extension GameData {
    
    init(bson: Document) throws {
        guard let id = Int(bson["_id"]) else {
            try logAndThrow(BSONError.missingField(name: "_id"))
        }
        guard let name = String(bson["name"]) else {
            try logAndThrow(BSONError.missingField(name: "name"))
        }
        let names: [String]? = try {
            if let names = Array(bson["names"]) {
                return try names.map {
                    guard let name = String($0) else {
                        try logAndThrow(BSONError.invalidField(name: "names"))
                    }
                    return name
                }
            } else {
                return nil
            }
        }()
        guard let yearPublished = Int(bson["yearPublished"]) else {
            try logAndThrow(BSONError.missingField(name: "yearPublished"))
        }
        guard let minPlayers = Int(bson["minPlayers"]) else {
            try logAndThrow(BSONError.missingField(name: "minPlayers"))
        }
        guard let maxPlayers = Int(bson["maxPlayers"]) else {
            try logAndThrow(BSONError.missingField(name: "maxPlayers"))
        }
        let playerCount = minPlayers...maxPlayers
        guard let minPlayingTime = Int(bson["minPlayingTime"]) else {
            try logAndThrow(BSONError.missingField(name: "minPlayingTime"))
        }
        guard let maxPlayingTime = Int(bson["maxPlayingTime"]) else {
            try logAndThrow(BSONError.missingField(name: "maxPlayingTime"))
        }
        let playingTime = minPlayingTime...maxPlayingTime
        let picture: URL? = {
            if let urlString = String(bson["picture"]) {
                return URL(string: urlString)
            } else {
                return nil
            }
        }()
        let thumbnail: URL? = {
            if let urlString = String(bson["thumbnail"]) {
                return URL(string: urlString)
            } else {
                return nil
            }
        }()
        self.init(id: id,
                  name: name,
                  names: names,
                  yearPublished: yearPublished,
                  playerCount: playerCount,
                  playingTime: playingTime,
                  picture: picture,
                  thumbnail: thumbnail)
    }
    
    func toBSON() -> Document {
        var bson: Document = [
            "_id": id,
            "name": name,
            "yearPublished": yearPublished,
            "minPlayers": playerCount.lowerBound,
            "maxPlayers": playerCount.upperBound,
            "minPlayingTime": playingTime.lowerBound,
            "maxPlayingTime": playingTime.upperBound
        ]
        if let names = names {
            bson["names"] = names
        }
        if let picture = picture {
            bson["picture"] = picture.absoluteString
        }
        if let thumbnail = thumbnail {
            bson["thumbnail"] = thumbnail.absoluteString
        }
        return bson
    }
}
