import BSON
import Foundation

/**
 A conversation between two users regarding an activity.
 */
final class Conversation {
    
    /// The conversation's ID.
    /// If set to nil, an ID is assigned when the instance is persisted.
    var id: Int?
    
    /// The activity this conversation is about.
    let topic: Activity
    
    /// The user who initiated the conversation.
    let sender: User
    
    /// The user with whom the conversation was initiated.
    let recipient: User
    
    /**
     A message that is part of a conversation.
     
     Note that the message's sender and recipient are not stored.
     To avoid duplication, only the direction relative to the conversation is stored.
     */
    struct Message {
        
        /// The date and time at which the message was sent.
        let timestamp: Date
        
        /**
         The direction of a message.
         */
        enum Direction: String {
            
            /// An incoming message is sent to the conversation's initiator.
            case incoming
            
            /// An outgoing message is sent from the conversation's initiator.
            case outgoing
        }
        
        /// The direction of the message.
        let direction: Direction
        
        /// The text of the message.
        let text: String
        
        /// Whether the message is read by the receiver.
        var isRead: Bool
        
        /**
         Initializes a `Message`.
         
         `timestamp` is set to the current date and time by default.
         `isRead` is set to `false` by default.
         */
        init(timestamp: Date = Date(), direction: Direction, text: String, isRead: Bool = false) {
            self.timestamp = timestamp
            self.direction = direction
            self.text = text
            self.isRead = isRead
        }
    }
    
    /// The thread of messages in this conversation.
    var messages: [Message]
    
    /**
     Initializes a `Conversation`.
     
     `id` should be set to nil for new (unpersisted) instances. This is also its default value.
     `messages` is set to an empty array by default.
     */
    init(id: Int? = nil, topic: Activity, sender: User, recipient: User, messages: [Message] = []) {
        self.id = id
        self.topic = topic
        self.sender = sender
        self.recipient = recipient
        self.messages = messages
    }
}

/**
 Adds `Equatable` conformance to `Conversation`.
 
 Conversations are considered equal if they have the same `id`.
 */
extension Conversation: Equatable {
    
    static func ==(lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.id == rhs.id
    }
}

/**
 Adds `BSON.Primitive` conformance to `Conversation.Message`.
 */
extension Conversation.Message: Primitive {
    
    /// A `Message` is stored as a BSON `Document`.
    var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `Message` as a BSON `Document`.
    var document: Document {
        return [
            "timestamp": timestamp,
            "direction": direction.rawValue,
            "text": text,
            "isRead": isRead
        ]
    }
    
    /**
     Returns this `Message` as a BSON `Document` in binary form.
     */
    func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes a `Message` from a BSON primitive.
     
     - Returns: `nil` when the primitive is not a `Document`.
     - Throws: a `BSONError` when the document does not contain all required properties.
     */
    init?(_ bson: Primitive?) throws {
        guard let bson = bson as? Document else {
            return nil
        }
        guard let timestamp = Date(bson["timestamp"]) else {
            throw log(BSONError.missingField(name: "timestamp"))
        }
        guard let directionRaw = String(bson["direction"]),
              let direction = Direction(rawValue: directionRaw) else {
            throw log(BSONError.missingField(name: "timestamp"))
        }
        guard let text = String(bson["text"]) else {
            throw log(BSONError.missingField(name: "text"))
        }
        guard let isRead = Bool(bson["isRead"]) else {
            throw log(BSONError.missingField(name: "isRead"))
        }
        self.init(timestamp: timestamp, direction: direction, text: text, isRead: isRead)
    }
}

/**
 Adds `BSON.Primitive` conformance to `Conversation`.
 */
extension Conversation: Primitive {
    
    /// A `Conversation` is stored as a BSON `Document`.
    var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `Conversation` as a BSON `Document`.
    /// `topic`, `sender` and `recipient` are normalized and stored as references.
    var document: Document {
        return [
            "_id": id,
            "topic": topic.id, // Normalized.
            "sender": sender.id, // Normalized.
            "recipient": recipient.id, // Normalized.
            "messages": messages
        ]
    }
    
    /**
     Returns this `Conversation` as a BSON `Document` in binary form.
     */
    func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes a `Conversation` from a BSON primitive.
     
     `topic`, `sender` and `recipient` must be denormalized before decoding.
     
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
        guard let topic = try Activity(bson["topic"]) else {
            throw log(BSONError.missingField(name: "topic"))
        }
        guard let sender = try User(bson["sender"]) else {
            throw log(BSONError.missingField(name: "sender"))
        }
        guard let recipient = try User(bson["recipient"]) else {
            throw log(BSONError.missingField(name: "recipient"))
        }
        guard let messages = try Array(bson["messages"])?.compactMap({ try Message($0) }) else {
            throw log(BSONError.missingField(name: "messages"))
        }
        self.init(id: id,
                  topic: topic,
                  sender: sender,
                  recipient: recipient,
                  messages: messages)
    }
}
