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
     - Throws: ServerError.conflict if there already is a conversation between the two users.
     */
    func add(_ conversation: Conversation) throws {
        guard conversation.id == nil else {
            throw log(ServerError.persistedEntity)
        }
        guard try self.conversation(between: conversation.sender, conversation.recipient) == nil else {
            throw log(ServerError.conflict)
        }
        conversation.id = try nextID(for: conversations)
        try conversations.insert(conversation.document) 
    }
    
    /**
     Returns the conversation between the two given users or `nil` if no conversation exists.
     
     - Throws: ServerError.unpersistedEntity if one of the users hasn't been persisted yet.
     */
    func conversation(between first: User, _ second: User) throws -> Conversation? {
        guard let first = first.id,
              let second = second.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let results = try conversations.aggregate([
            .match([
                "$or": [
                    ["sender": first, "recipient": second],
                    ["sender": second, "recipient": first],
                ]
            ] as Query),
            .limit(1),
            // Denormalize `sender`.
            .lookup(from: users, localField: "sender", foreignField: "_id", as: "sender"),
            .unwind("$sender"),
            // Denormalize `recipient`.
            .lookup(from: users, localField: "recipient", foreignField: "_id", as: "recipient"),
            .unwind("$recipient")
        ])
        return try Conversation(results.next())
    }
    
    /**
     Returns all conversations involving the given user.
     
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
            // Denormalize `sender`.
            .lookup(from: users, localField: "sender", foreignField: "_id", as: "sender"),
            .unwind("$sender"),
            // Denormalize `recipient`.
            .lookup(from: users, localField: "recipient", foreignField: "_id", as: "recipient"),
            .unwind("$recipient"),
            // Sort by the most recent message.
            AggregationPipeline.Stage(["$addFields": ["latestMessage": ["$max": "$messages.timestamp"]]]),
            .sort(["latestMessage": .descending])
        ])
        return try results.compactMap(Conversation.init)
    }
    
    /**
     Returns the number of unread messages for the given user.
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
            ] as Query),
            .count(insertedAtKey: "count")
        ])
        guard let result = results.next(),
              let count = Int(result["count"]) else {
            // the $count stage doesn't return a count when the pipeline has 0 documents.
            return 0
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
