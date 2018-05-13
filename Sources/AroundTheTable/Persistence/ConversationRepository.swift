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
        guard let id = try collection(.conversations).insert(conversation.document) as? ObjectId else {
            throw log(BSONError.missingField(name: "_id"))
        }
        conversation.id = id
    }
    
    /**
     Looks up the conversation between the two given users regarding the given activity.
 
     Returns `nil` if such a conversation doesn't exist.
     
     - Throws: ServerError.unpersistedEntity if the activity hasn't been persisted yet.
     */
    func conversation(between first: User, _ second: User, regarding topic: Activity) throws -> Conversation? {
        guard let id = topic.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let results = try collection(.conversations).aggregate([
            .match([
                "topic": id,
                "$or": [
                    ["sender": first.id, "recipient": second.id],
                    ["sender": second.id, "recipient": first.id],
                ]
            ] as Query),
            .limit(1),
            // Denormalize `topic`.
            .lookup(from: collection(.activities), localField: "topic", foreignField: "_id", as: "topic"),
            .unwind("$topic"),
            // Denormalize `topic.host`.
            .lookup(from: collection(.users), localField: "topic.host", foreignField: "_id", as: "topic.host"),
            .unwind("$topic.host"),
            // Denormalize `topic.game`.
            .lookup(from: collection(.games), localField: "topic.game", foreignField: "_id", as: "topic.game"),
            .unwind("$topic.game", preserveNullAndEmptyArrays: true),
            // Denormalize `sender`.
            .lookup(from: collection(.users), localField: "sender", foreignField: "_id", as: "sender"),
            .unwind("$sender"),
            // Denormalize `recipient`.
            .lookup(from: collection(.users), localField: "recipient", foreignField: "_id", as: "recipient"),
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
                guard let id = String(registration["player"]),
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
        let yesterday = Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: Date())
        let results = try collection(.conversations).aggregate([
            .match([
                "$or": [
                    ["sender": user.id],
                    ["recipient": user.id]
                ]
            ] as Query),
            // Denormalize `topic`.
            .lookup(from: collection(.activities), localField: "topic", foreignField: "_id", as: "topic"),
            .unwind("$topic"),
            // Filter only active conversations.
            .match(["topic.date": ["$gt": yesterday]] as Query),
            // Denormalize `topic.host`.
            .lookup(from: collection(.users), localField: "topic.host", foreignField: "_id", as: "topic.host"),
            .unwind("$topic.host"),
            // Denormalize `topic.game`.
            .lookup(from: collection(.games), localField: "topic.game", foreignField: "_id", as: "topic.game"),
            .unwind("$topic.game", preserveNullAndEmptyArrays: true),
            // Denormalize `sender`.
            .lookup(from: collection(.users), localField: "sender", foreignField: "_id", as: "sender"),
            .unwind("$sender"),
            // Denormalize `recipient`.
            .lookup(from: collection(.users), localField: "recipient", foreignField: "_id", as: "recipient"),
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
                guard let id = String(registration["player"]),
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
        let yesterday = Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: Date())
        let results = try collection(.conversations).aggregate([
            // Find all conversations with unread messages for this user.
            .match([
                "$or": [
                    [
                        "sender": user.id,
                        "messages": [ "$elemMatch": ["isRead": false, "direction": "incoming"]]
                    ],
                    [
                        "recipient": user.id,
                        "messages": [ "$elemMatch": ["isRead": false, "direction": "outgoing"]]
                    ]
                ]
            ] as Query),
            // Denormalize `topic`.
            .lookup(from: collection(.activities), localField: "topic", foreignField: "_id", as: "topic"),
            .unwind("$topic"),
            // Filter only active conversations.
            .match(["topic.date": ["$gt": yesterday]] as Query),
            // Unwind `messages` and filter only unread messages.
            .unwind("$messages"),
            .match([
                "messages.isRead": false,
                "$or": [
                    [
                        "sender": user.id,
                        "messages.direction": "incoming"
                    ],
                    [
                        "recipient": user.id,
                        "messages.direction": "outgoing"
                    ]
                ]
            ] as Query),
            .count(insertedAtKey: "unreadMessageCount")
        ])
        guard let result = results.next(),
              let count = Int(result["unreadMessageCount"]) else {
            throw log(BSONError.missingField(name: "unreadMessageCount"))
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
        try collection(.conversations).update(["_id": id], to: conversation.document)
    }
}
