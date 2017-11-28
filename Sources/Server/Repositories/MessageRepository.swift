import Foundation
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
    
    func unreadMessageCount(for user: User) throws -> Int {
        return try collection(.messages).count(["recipient": user.id, "read": false])
    }
    
    func messages(for user: User) throws -> [Message] {
        let results = try collection(.messages).find(["recipient": user.id], sortedBy: ["creationDate": .descending])
        return try results.map { try Message(bson: $0) }.filter {
            switch $0.category {
            case .hostCancelledGame(let game):
                return game.date.compare(Date()) == .orderedDescending
            case .hostCancelledRequest(let request),
                 .playerCancelledRequest(let request),
                 .requestApproved(let request),
                 .requestReceived(let request):
                return request.game.date.compare(Date()) == .orderedDescending
            }
        }
    }
    
    func markAllAsRead(for user: User) throws {
        try collection(.messages).update(["recipient": user.id], to: ["$set": ["read": true]], multiple: true)
    }
}
