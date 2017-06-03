import Foundation

final class Message {
    
    enum Category {
        
        case requestApproved(Request)
        case requestReceived(Request)
        
        var description: String {
            switch self {
            case .requestApproved:
                return "requestApproved"
            case .requestReceived:
                return "requestReceived"
            }
        }
    }
    
    var id: String? // Will be filled in when the instance is persisted. Never set this yourself!
    let creationDate: Date
    let category: Category
    let recipient: User
    var read: Bool
    
    init(category: Category, recipient: User) {
        creationDate = Date()
        self.category = category
        self.recipient = recipient
        read = false
    }
    
    fileprivate init(id: String, creationDate: Date, category: Category, recipient: User, read: Bool) {
        self.id = id
        self.creationDate = creationDate
        self.category = category
        self.recipient = recipient
        self.read = read
    }
}

// MARK: - BSON

import BSON

extension Message {
    
    convenience init(bson: Document) throws {
        guard let id = ObjectId(bson["_id"])?.hexString else {
            try logAndThrow(BSONError.missingField(name: "_id"))
        }
        guard let creationDate = Date(bson["creationDate"]) else {
            try logAndThrow(BSONError.missingField(name: "creationDate"))
        }
        let category: Category = try {
            guard let category = String(bson["category"]) else {
                try logAndThrow(BSONError.missingField(name: "category"))
            }
            switch category {
            case "requestReceived":
                guard let requestID = String(bson["request"]) else {
                    try logAndThrow(BSONError.missingField(name: "request"))
                }
                guard let request = try RequestRepository().request(withID: requestID) else {
                    try logAndThrow(BSONError.invalidField(name: "request"))
                }
                return Category.requestReceived(request)
            case "requestApproved":
                guard let requestID = String(bson["request"]) else {
                    try logAndThrow(BSONError.missingField(name: "request"))
                }
                guard let request = try RequestRepository().request(withID: requestID) else {
                    try logAndThrow(BSONError.invalidField(name: "request"))
                }
                return Category.requestApproved(request)
            default:
                try logAndThrow(BSONError.invalidField(name: "category"))
            }
        }()
        guard let recipientID = String(bson["recipient"]) else {
            try logAndThrow(BSONError.missingField(name: "recipient"))
        }
        guard let recipient = try UserRepository().user(withID: recipientID) else {
            try logAndThrow(BSONError.invalidField(name: "recipient"))
        }
        guard let read = Bool(bson["read"]) else {
            try logAndThrow(BSONError.missingField(name: "read"))
        }
        self.init(id: id,
                  creationDate: creationDate,
                  category: category,
                  recipient: recipient,
                  read: read)
    }
    
    func toBSON() throws -> Document {
        var bson: Document = [
            "creationDate": creationDate,
            "recipient": recipient.id,
            "read": read
        ]
        if let id = id {
            bson["_id"] = try ObjectId(id)
        }
        bson["category"] = category.description
        switch category {
        case .requestReceived(let request), .requestApproved(let request):
            guard let id = request.id else {
                try logAndThrow(ServerError.unpersistedEntity)
            }
            bson["request"] = id
        }
        return bson
    }
}
