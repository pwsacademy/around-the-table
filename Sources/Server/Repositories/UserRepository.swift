import MongoKitten

struct UserRepository {

    func add(_ user: User) throws {
        guard try self.user(withID: user.id) == nil else {
            try logAndThrow(ServerError.persistedEntity)
        }
        try collection(.users).insert(user.toBSON())
    }
    
    func user(withID id: String) throws -> User? {
        return try collection(.users).findOne(["_id": id]).map { try User(bson: $0) }
    }
    
    func players(`for` game: Game) throws -> [User] {
        guard let id = game.id else {
            try logAndThrow(ServerError.unpersistedEntity)
        }
        let playerIDs = try collection(.requests)
            .find(["game": id, "approved": true, "cancelled": false], projecting: ["_id": false, "player": true])
            .flatMap { String($0["player"]) }
        return try collection(.users).find(["_id": ["$in": Array(playerIDs)]]).map { try User(bson: $0) }
    }
}
