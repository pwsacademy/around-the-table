import Foundation

final class Request {
    
    var id: String? // Will be filled in when the instance is persisted. Never set this yourself!
    let creationDate: Date
    let player: User
    let game: Game
    let seats: Int
    var approved: Bool
    
    init(player: User, game: Game, seats: Int = 1) {
        creationDate = Date()
        self.player = player
        self.game = game
        self.seats = seats
        approved = false
    }
    
    fileprivate init(id: String, creationDate: Date, player: User, game: Game, seats: Int, approved: Bool) {
        self.id = id
        self.creationDate = creationDate
        self.player = player
        self.game = game
        self.seats = seats
        self.approved = approved
    }
}

// MARK: - BSON

import BSON

extension Request {
    
    convenience init(bson: Document) throws {
        guard let id = ObjectId(bson["_id"])?.hexString else {
            try logAndThrow(BSONError.missingField(name: "_id"))
        }
        guard let creationDate = Date(bson["creationDate"]) else {
            try logAndThrow(BSONError.missingField(name: "creationDate"))
        }
        guard let playerID = String(bson["player"]) else {
            try logAndThrow(BSONError.missingField(name: "player"))
        }
        guard let player = try UserRepository().user(withID: playerID) else {
            try logAndThrow(BSONError.invalidField(name: "player"))
        }
        guard let gameID = String(bson["game"]) else {
            try logAndThrow(BSONError.missingField(name: "game"))
        }
        guard let game = try GameRepository().game(withID: gameID) else {
            try logAndThrow(BSONError.invalidField(name: "game"))
        }
        guard let seats = Int(bson["seats"]) else {
            try logAndThrow(BSONError.missingField(name: "seats"))
        }
        guard let approved = Bool(bson["approved"]) else {
            try logAndThrow(BSONError.missingField(name: "approved"))
        }
        self.init(id: id,
                  creationDate: creationDate,
                  player: player,
                  game: game,
                  seats: seats,
                  approved: approved)
    }
    
    func toBSON() throws -> Document {
        var bson: Document = [
            "creationDate": creationDate,
            "player": player.id,
            "game": game.id,
            "seats": seats,
            "approved": approved
        ]
        if let id = id {
            bson["_id"] = try ObjectId(id)
        }
        return bson
    }
}
