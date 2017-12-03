import Foundation

final class Message {
    
    enum Category {
        
        case hostChangedAddress(Game)
        case hostChangedDate(Game)
        case hostCancelledGame(Game)
        case hostCancelledRequest(Request)
        case playerCancelledRequest(Request)
        case requestApproved(Request)
        case requestReceived(Request)
        
        var description: String {
            switch self {
            case .hostChangedAddress:
                return "hostChangedAddress"
            case .hostChangedDate:
                return "hostChangedDate"
            case .hostCancelledGame:
                return "hostCancelledGame"
            case .hostCancelledRequest:
                return "hostCancelledRequest"
            case .playerCancelledRequest:
                return "playerCancelledRequest"
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
            case "hostChangedAddress":
                guard let gameID = String(bson["game"]) else {
                    try logAndThrow(BSONError.missingField(name: "game"))
                }
                guard let game = try GameRepository().game(withID: gameID) else {
                    try logAndThrow(BSONError.invalidField(name: "game"))
                }
                return Category.hostChangedAddress(game)
            case "hostChangedDate":
                guard let gameID = String(bson["game"]) else {
                    try logAndThrow(BSONError.missingField(name: "game"))
                }
                guard let game = try GameRepository().game(withID: gameID) else {
                    try logAndThrow(BSONError.invalidField(name: "game"))
                }
                return Category.hostChangedDate(game)
            case "hostCancelledGame":
                guard let gameID = String(bson["game"]) else {
                    try logAndThrow(BSONError.missingField(name: "game"))
                }
                guard let game = try GameRepository().game(withID: gameID) else {
                    try logAndThrow(BSONError.invalidField(name: "game"))
                }
                return Category.hostCancelledGame(game)
            case "hostCancelledRequest":
                guard let requestID = String(bson["request"]) else {
                    try logAndThrow(BSONError.missingField(name: "request"))
                }
                guard let request = try RequestRepository().request(withID: requestID) else {
                    try logAndThrow(BSONError.invalidField(name: "request"))
                }
                return Category.hostCancelledRequest(request)
            case "playerCancelledRequest":
                guard let requestID = String(bson["request"]) else {
                    try logAndThrow(BSONError.missingField(name: "request"))
                }
                guard let request = try RequestRepository().request(withID: requestID) else {
                    try logAndThrow(BSONError.invalidField(name: "request"))
                }
                return Category.playerCancelledRequest(request)
                
            case "requestApproved":
                guard let requestID = String(bson["request"]) else {
                    try logAndThrow(BSONError.missingField(name: "request"))
                }
                guard let request = try RequestRepository().request(withID: requestID) else {
                    try logAndThrow(BSONError.invalidField(name: "request"))
                }
                return Category.requestApproved(request)
            case "requestReceived":
                guard let requestID = String(bson["request"]) else {
                    try logAndThrow(BSONError.missingField(name: "request"))
                }
                guard let request = try RequestRepository().request(withID: requestID) else {
                    try logAndThrow(BSONError.invalidField(name: "request"))
                }
                return Category.requestReceived(request)
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
        case .hostChangedAddress(let game),
             .hostChangedDate(let game),
             .hostCancelledGame(let game):
            guard let id = game.id else {
                try logAndThrow(ServerError.unpersistedEntity)
            }
            bson["game"] = id
        case .hostCancelledRequest(let request),
             .playerCancelledRequest(let request),
             .requestApproved(let request),
             .requestReceived(let request):
            guard let id = request.id else {
                try logAndThrow(ServerError.unpersistedEntity)
            }
            bson["request"] = id
        }
        return bson
    }
}
