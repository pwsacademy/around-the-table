import Foundation

final class Game {
    
    var id: String? // Will be filled in when the instance is persisted. Never set this yourself!
    let creationDate: Date
    let host: User
    let prereservedSeats: Int // Used when the hosts wants to reserve seats.
    var availableSeats: Int // Denormalized, required to filter out games that are fully booked.
    let data: GameData
    let date: Date
    let deadline: Date // Deadline for submitting requests.
    let location: Location
    let info: String
    
    init(host: User, prereservedSeats: Int = 1, data: GameData, date: Date, deadline: Date, location: Location, info: String = "") {
        creationDate = Date()
        self.host = host
        self.prereservedSeats = prereservedSeats
        availableSeats = data.playerCount.upperBound - prereservedSeats
        self.data = data
        self.date = date
        self.deadline = deadline
        self.location = location
        self.info = info
    }
    
    fileprivate init(id: String, creationDate: Date, host: User, prereservedSeats: Int, availableSeats: Int, data: GameData, date: Date, deadline: Date, location: Location, info: String) {
        self.id = id
        self.creationDate = creationDate
        self.host = host
        self.prereservedSeats = prereservedSeats
        self.availableSeats = availableSeats
        self.data = data
        self.date = date
        self.deadline = deadline
        self.location = location
        self.info = info
    }
}

// MARK: - BSON

import BSON

extension Game {
    
    convenience init(bson: Document) throws {
        guard let id = ObjectId(bson["_id"])?.hexString else {
            try logAndThrow(BSONError.missingField(name: "_id"))
        }
        guard let creationDate = Date(bson["creationDate"]) else {
            try logAndThrow(BSONError.missingField(name: "creationDate"))
        }
        guard let hostID = String(bson["host"]) else {
            try logAndThrow(BSONError.missingField(name: "host"))
        }
        guard let host = try UserRepository().user(withID: hostID) else {
            try logAndThrow(BSONError.invalidField(name: "host"))
        }
        guard let prereservedSeats = Int(bson["prereservedSeats"]) else {
            try logAndThrow(BSONError.missingField(name: "prereservedSeats"))
        }
        guard let availableSeats = Int(bson["availableSeats"]) else {
            try logAndThrow(BSONError.missingField(name: "availableSeats"))
        }
        guard let data = Document(bson["data"]) else {
            try logAndThrow(BSONError.missingField(name: "data"))
        }
        guard let date = Date(bson["date"]) else {
            try logAndThrow(BSONError.missingField(name: "date"))
        }
        guard let deadline = Date(bson["deadline"]) else {
            try logAndThrow(BSONError.missingField(name: "deadline"))
        }
        guard let location = Document(bson["location"]) else {
            try logAndThrow(BSONError.missingField(name: "location"))
        }
        guard let info = String(bson["info"]) else {
            try logAndThrow(BSONError.missingField(name: "info"))
        }
        self.init(id: id,
                  creationDate: creationDate,
                  host: host,
                  prereservedSeats: prereservedSeats,
                  availableSeats: availableSeats,
                  data: try GameData(bson: data),
                  date: date,
                  deadline: deadline,
                  location: try Location(bson: location),
                  info: info)
    }
    
    func toBSON() throws -> Document {
        var bson: Document = [
            "creationDate": creationDate,
            "host": host.id,
            "prereservedSeats": prereservedSeats,
            "availableSeats": availableSeats,
            "data": data.toBSON(),
            "date": date,
            "deadline": deadline,
            "location": location.toBSON(),
            "info": info
        ]
        if let id = id {
            bson["_id"] = try ObjectId(id)
        }
        return bson
    }
}
