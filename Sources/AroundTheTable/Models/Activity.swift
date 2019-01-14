import BSON
import Foundation

/**
 A gaming activity.
 
 An activity is created by a host who sets the date and time, and optionally a headlining game.
 Users can then request to join this activity by submitting a registration.
 */
final class Activity {
    
    /// The activity's ID.
    /// If set to nil, an ID is assigned when the instance is persisted.
    var id: Int?
    
    /// The date and time at which the activity was created.
    let creationDate: Date
    
    /// The host.
    /// This is the user who created the activity.
    let host: User
    
    /// The display name for the activity.
    /// This is usually the name of the headlining game, if there is one.
    let name: String
    
    /// The headlining game.
    /// If this is `nil`, players determine the game together.
    let game: Game?
    
    /// The possible player counts for the activity.
    /// Neither the lower or upper bound are enforced.
    /// The final decision always lies with the host.
    var playerCount: ClosedRange<Int>
    
    /// The number of seats pre-reserved by the host.
    var prereservedSeats: Int
    
    /// The date and time of the activity.
    var date: Date
    
    /// The deadline for submitting registrations.
    var deadline: Date
    
    /// The location at which the activity will take place.
    var location: Location
    
    /// The distance from this activity's location to the current user.
    /// This property is only used during queries, e.g. when a user searches for activities.
    let distance: Double?
    
    /// Additional information about the activity.
    var info: String
    
    /// An image for the activity.
    /// If this is `nil`, a default image will be used.
    var picture: URL?
    
    /// Whether the host has cancelled the activity.
    var isCancelled: Bool
    
    /**
     A registration by a user for this activity.
     
     A registration must be approved by the host before it takes effect.
     */
    struct Registration {
        
        /// The date and time at which the registration was created.
        let creationDate: Date
        
        /// The user who is requesting to join.
        let player: User
        
        /// The number of seats requested.
        let seats: Int
        
        /// Whether the host has approved this registration.
        var isApproved: Bool
        
        /// Whether this registration has been cancelled.
        /// A registration can be cancelled by both player and host.
        var isCancelled: Bool
        
        /**
         Initializes a `Registration`.
         
         `creationDate` is set to the current date and time by default.
         `approved` and `cancelled` are set to `false` by default.
         */
        init(creationDate: Date = Date(), player: User, seats: Int, isApproved: Bool = false, isCancelled: Bool = false) {
            self.creationDate = creationDate
            self.player = player
            self.seats = seats
            self.isApproved = isApproved
            self.isCancelled = isCancelled
        }
    }
    
    /// The registrations that have been submitted for this activity.
    var registrations: [Registration]
    
    /// The approved registrations for this activity.
    /// This is a computed property.
    var approvedRegistrations: [Registration] {
        return registrations.filter { $0.isApproved && !$0.isCancelled }
    }
    
    /// The pending (not yet approved) registrations for this activity.
    /// This is a computed property.
    var pendingRegistrations: [Registration] {
        return registrations.filter { !$0.isApproved && !$0.isCancelled }
    }
    
    /// The players who've joined this activity.
    /// This does not include the host.
    /// This is a computed property.
    var players: [User] {
        return approvedRegistrations.map { $0.player }
    }
    
    /// The number of seats still available.
    /// This is a computed property.
    var availableSeats: Int {
        let approvedSeats = approvedRegistrations.map { $0.seats }.reduce(0, +)
        return max(0, playerCount.upperBound - prereservedSeats - approvedSeats)
    }
    
    /**
     Initializes an `Activity`.
     
     `id` should be set to nil for new (unpersisted) instances. This is also its default value.
     `creationDate` is set to the current date and time by default.
     `distance` is set to `nil` by default.
     If `picture` is `nil` and a headlining game is set, that game's image will be used.
     `isCancelled` is set to `false` by default.
     `registrations` is set to an empty array by default.
     */
    init(id: Int? = nil, creationDate: Date = Date(),
         host: User,
         name: String, game: Game?,
         playerCount: ClosedRange<Int>, prereservedSeats: Int,
         date: Date, deadline: Date,
         location: Location, distance: Double? = nil,
         info: String,
         picture: URL? = nil,
         isCancelled: Bool = false,
         registrations: [Registration] = []) {
        self.id = id
        self.creationDate = creationDate
        self.host = host
        self.name = name
        self.game = game
        self.playerCount = playerCount
        self.prereservedSeats = prereservedSeats
        self.date = date
        self.deadline = deadline
        self.location = location
        self.distance = distance
        self.info = info
        self.picture = picture ?? game?.thumbnail
        self.isCancelled = isCancelled
        self.registrations = registrations
    }
}

/**
 Adds `Equatable` conformance to `Activity`.
 
 Activities are considered equal if they have the same `id`.
 */
extension Activity: Equatable {
    
    static func ==(lhs: Activity, rhs: Activity) -> Bool {
        return lhs.id == rhs.id
    }
}

/**
 Adds `BSON.Primitive` conformance to `Registration`.
 */
extension Activity.Registration: Primitive {
    
    /// A `Registration` is stored as a BSON `Document`.
    var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `Registration` as a BSON `Document`.
    /// `player` is normalized and stored as a reference.
    var document: Document {
        return [
            "creationDate": creationDate,
            "player": player.id, // Normalized.
            "seats": seats,
            "isApproved": isApproved,
            "isCancelled": isCancelled
        ]
    }
    
    /**
     Returns this `Registration` as a BSON `Document` in binary form.
     */
    func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes a `Registration` from a BSON primitive.
     
     `player` must be denormalized before decoding.
     
     - Returns: `nil` when the primitive is not a `Document`.
     - Throws: a `BSONError` when the document does not contain all required properties.
     */
    init?(_ bson: Primitive?) throws {
        guard let bson = bson as? Document else {
            return nil
        }
        guard let creationDate = Date(bson["creationDate"]) else {
            throw log(BSONError.missingField(name: "creationDate"))
        }
        guard let player = try User(bson["player"]) else {
            throw log(BSONError.missingField(name: "player"))
        }
        guard let seats = Int(bson["seats"]) else {
            throw log(BSONError.missingField(name: "seats"))
        }
        guard let isApproved = Bool(bson["isApproved"]) else {
            throw log(BSONError.missingField(name: "isApproved"))
        }
        guard let isCancelled = Bool(bson["isCancelled"]) else {
            throw log(BSONError.missingField(name: "isCancelled"))
        }
        self.init(creationDate: creationDate,
                  player: player,
                  seats: seats,
                  isApproved: isApproved,
                  isCancelled: isCancelled)
    }
}

/**
 Adds `BSON.Primitive` conformance to `Activity`.
 */
extension Activity: Primitive {
    
    /// An `Activity` is stored as a BSON `Document`.
    var typeIdentifier: Byte {
        return Document().typeIdentifier
    }
    
    /// This `Activity` as a BSON `Document`.
    /// Optional properties are included only when they are not `nil`.
    /// `host` and `game` are normalized and stored as references.
    var document: Document {
        var document: Document = [
            "_id": id,
            "creationDate": creationDate,
            "host": host.id, // Normalized.
            "name": name,
            "playerCount": playerCount,
            "prereservedSeats": prereservedSeats,
            "date": date,
            "deadline": deadline,
            "location": location,
            "info": info,
            "isCancelled": isCancelled,
            "registrations": registrations
        ]
        if let game = game {
            document["game"] = game.id // Normalized.
        }
        if let picture = picture {
            document["picture"] = picture
        }
        return document
    }
    
    /**
     Returns this `Activity` as a BSON `Document` in binary form.
     */
    func makeBinary() -> Bytes {
        return document.makeBinary()
    }
    
    /**
     Decodes an `Activity` from a BSON primitive.
     
     `host` and `game` must be denormalized before decoding.
     
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
        guard let creationDate = Date(bson["creationDate"]) else {
            throw log(BSONError.missingField(name: "creationDate"))
        }
        guard let host = try User(bson["host"]) else {
            throw log(BSONError.missingField(name: "host"))
        }
        guard let name = String(bson["name"]) else {
            throw log(BSONError.missingField(name: "name"))
        }
        guard let playerCount = try ClosedRange<Int>(bson["playerCount"]) else {
            throw log(BSONError.missingField(name: "playerCount"))
        }
        guard let prereservedSeats = Int(bson["prereservedSeats"]) else {
            throw log(BSONError.missingField(name: "prereservedSeats"))
        }
        guard let date = Date(bson["date"]) else {
            throw log(BSONError.missingField(name: "date"))
        }
        guard let deadline = Date(bson["deadline"]) else {
            throw log(BSONError.missingField(name: "deadline"))
        }
        guard let location = try Location(bson["location"]) else {
            throw log(BSONError.missingField(name: "location"))
        }
        guard let info = String(bson["info"]) else {
            throw log(BSONError.missingField(name: "info"))
        }
        guard let isCancelled = Bool(bson["isCancelled"]) else {
            throw log(BSONError.missingField(name: "isCancelled"))
        }
        guard let registrations = try Array(bson["registrations"])?.compactMap({ try Registration($0) }) else {
            throw log(BSONError.missingField(name: "registrations"))
        }
        let game = try Game(bson["game"])
        let distance = Double(bson["distance"])
        let picture = try URL(bson["picture"])
        self.init(id: id,
                  creationDate: creationDate,
                  host: host,
                  name: name,
                  game: game,
                  playerCount: playerCount,
                  prereservedSeats: prereservedSeats,
                  date: date,
                  deadline: deadline,
                  location: location,
                  distance: distance,
                  info: info,
                  picture: picture,
                  isCancelled: isCancelled,
                  registrations: registrations)
    }
}
