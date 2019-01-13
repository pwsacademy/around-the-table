import Foundation
import MongoKitten

/**
 Persistence methods related to conversations.
 */
extension Persistence {
    
    /**
     Adds a new conversation to the database.
     
     The conversation will be assigned an ID as part of this operation.
     
     - Throws: ServerError.persistedEntity if the conversation already has an ID.
               Use `update(_:)` to update existing conversations.
     */
    func add(_ conversation: Conversation) throws {
        guard conversation.id == nil else {
            throw log(ServerError.persistedEntity)
        }
        conversation.id = try nextID(for: conversations)
        try conversations.insert(conversation.document) 
    }
    
    /**
     Looks up the conversation between the two given users regarding the given activity.
 
     Returns `nil` if such a conversation doesn't exist.
     
     - Throws: ServerError.unpersistedEntity if the activity or one of the users hasn't been persisted yet.
     */
    func conversation(between first: User, _ second: User, regarding topic: Activity) throws -> Conversation? {
        guard let id = topic.id,
              let first = first.id,
              let second = second.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let results = try conversations.aggregate([
            .match([
                "topic": id,
                "$or": [
                    ["sender": first, "recipient": second],
                    ["sender": second, "recipient": first],
                ]
            ] as Query),
            .limit(1),
            // Denormalize `topic`.
            .lookup(from: activities, localField: "topic", foreignField: "_id", as: "topic"),
            .unwind("$topic"),
            // Denormalize `topic.host`.
            .lookup(from: users, localField: "topic.host", foreignField: "_id", as: "topic.host"),
            .unwind("$topic.host"),
            // Denormalize `topic.game`.
            .lookup(from: games, localField: "topic.game", foreignField: "_id", as: "topic.game"),
            .unwind("$topic.game", preserveNullAndEmptyArrays: true),
            // Denormalize `sender`.
            .lookup(from: users, localField: "sender", foreignField: "_id", as: "sender"),
            .unwind("$sender"),
            // Denormalize `recipient`.
            .lookup(from: users, localField: "recipient", foreignField: "_id", as: "recipient"),
            .unwind("$recipient")
        ])
        return try results.compactMap {
            // Here we denormalize `topic.registrations[i].player`.
            // This is quite tricky to do in an aggregation pipeline,
            // so we use additional queries instead.
            var document = $0
            guard let registrations = Array(document["topic"]["registrations"])?.compactMap(Document.init) else {
                throw log(BSONError.missingField(name: "registrations"))
            }
            for (index, registration) in registrations.enumerated() {
                guard let id = Int(registration["player"]),
                      let player = try user(withID: id) else {
                    throw log(BSONError.missingField(name: "player"))
                }
                document["topic"]["registrations"][index]["player"] = player.document
            }
            return try Conversation(document)
        }.first
    }
    
    /**
     Returns all active conversations involving the given user.
     
     A conversation is active if it regards an activity that is less than 24 hours in the past.
     Results are sorted by the timestamp of the most recent message in a conversation, in descending order.
     */
    func conversations(for user: User) throws -> [Conversation] {
        guard let id = user.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let results = try conversations.aggregate([
            .match([
                "$or": [
                    ["sender": id],
                    ["recipient": id]
                ]
            ] as Query),
            // Denormalize `topic`.
            .lookup(from: activities, localField: "topic", foreignField: "_id", as: "topic"),
            .unwind("$topic"),
            // Filter only active conversations.
            .match(["topic.date": ["$gt": Date().previous]] as Query),
            // Denormalize `topic.host`.
            .lookup(from: users, localField: "topic.host", foreignField: "_id", as: "topic.host"),
            .unwind("$topic.host"),
            // Denormalize `topic.game`.
            .lookup(from: games, localField: "topic.game", foreignField: "_id", as: "topic.game"),
            .unwind("$topic.game", preserveNullAndEmptyArrays: true),
            // Denormalize `sender`.
            .lookup(from: users, localField: "sender", foreignField: "_id", as: "sender"),
            .unwind("$sender"),
            // Denormalize `recipient`.
            .lookup(from: users, localField: "recipient", foreignField: "_id", as: "recipient"),
            .unwind("$recipient"),
            // Sort by the most recent message.
            .sort(["messages.timestamp": .descending])
        ])
        return try results.compactMap {
            // Here we denormalize `topic.registrations[i].player`.
            // This is quite tricky to do in an aggregation pipeline,
            // so we use additional queries instead.
            var document = $0
            guard let registrations = Array(document["topic"]["registrations"])?.compactMap(Document.init) else {
                throw log(BSONError.missingField(name: "registrations"))
            }
            for (index, registration) in registrations.enumerated() {
                guard let id = Int(registration["player"]),
                      let player = try self.user(withID: id) else {
                    throw log(BSONError.missingField(name: "player"))
                }
                document["topic"]["registrations"][index]["player"] = player.document
            }
            return try Conversation(document)
        }
    }
    
    /**
     Returns the number of unread messages for the given user.
     
     Only messages in active conversations are counted.
     A conversation is active if it regards an activity that is less than 24 hours in the past.
     */
    func unreadMessageCount(for user: User) throws -> Int {
        guard let id = user.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let results = try conversations.aggregate([
            // Find all conversations with unread messages for this user.
            .match([
                "$or": [
                    [
                        "sender": id,
                        "messages": [ "$elemMatch": ["isRead": false, "direction": "incoming"]]
                    ],
                    [
                        "recipient": id,
                        "messages": [ "$elemMatch": ["isRead": false, "direction": "outgoing"]]
                    ]
                ]
            ] as Query),
            // Denormalize `topic`.
            .lookup(from: activities, localField: "topic", foreignField: "_id", as: "topic"),
            .unwind("$topic"),
            // Filter only active conversations.
            .match(["topic.date": ["$gt": Date().previous]] as Query),
            // Unwind `messages` and filter only unread messages.
            .unwind("$messages"),
            .match([
                "messages.isRead": false,
                "$or": [
                    [
                        "sender": id,
                        "messages.direction": "incoming"
                    ],
                    [
                        "recipient": id,
                        "messages.direction": "outgoing"
                    ]
                ]
            ] as Query)
        ])
        var count = 0
        while results.next() != nil {
            count += 1
        }
        return count
    }
    
    /**
     Updates the given conversation in the database.
     
     - Throws: ServerError.unpersistedEntity if the conversation hasn't been persisted yet.
               Use `add(_:)` to add new conversations to the database.
     */
    func update(_ conversation: Conversation) throws {
        guard let id = conversation.id else {
            throw log(ServerError.unpersistedEntity)
        }
        try conversations.update(["_id": id], to: conversation.document)
    }
}
