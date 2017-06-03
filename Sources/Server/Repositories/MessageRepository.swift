import MongoKitten

struct MessageRepository {
    
    func add(_ message: Message) throws {
        guard message.id == nil else {
            try logAndThrow(ServerError.persistedEntity)
        }
        guard let newID = try collection(.messages).insert(message.toBSON()) as? ObjectId else {
            try logAndThrow(BSONError.missingField(name: "_id"))
        }
        message.id = newID.hexString
    }
    
    func unreadMessageCount(`for` user: User) throws -> Int {
        return try collection(.messages).count(["recipient": user.id, "read": false])
    }
    
    func unreadMessages(`for` user: User) throws -> [Message] {
        let results = try collection(.messages).find(["recipient": user.id, "read": false], sortedBy: ["creationDate": .descending])
        return try results.map { try Message(bson: $0) }
    }
    
    func markAsRead(_ messages: [Message]) throws {
        let ids = try messages.map {
            (message: Message) -> ObjectId in
            guard let id = message.id else {
                try logAndThrow(ServerError.unpersistedEntity)
            }
            return try ObjectId(id)
        }
        try collection(.messages).update(["_id": ["$in": ids]], to: ["$set": ["read": true]], multiple: true)
    }
}
