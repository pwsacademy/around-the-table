import Foundation
import GeoJSON
import MongoKitten

/**
 Persistence methods related to activities.
 */
extension Persistence {
    
    /**
     Adds a new activity to the database.
     
     The activity will be assigned an ID as part of this operation.
     
     - Throws: ServerError.persistedEntity if the activity already has an ID.
               Use `update(_:)` to update existing activities.
     */
    func add(_ activity: Activity) throws {
        guard activity.id == nil else {
            throw log(ServerError.persistedEntity)
        }
        activity.id = try nextID(for: activities)
        try activities.insert(activity.document)
    }
    
    /**
     Looks up activities using a `geoNear` query and sets the `distance` property.
     
     All other methods should call this method to ensure activities are properly loaded.
     */
    private func activities(matching query: Query,
                            measuredFrom coordinates: Coordinates,
                            sortedBy sort: Sort,
                            skipping skip: Int,
                            limitedTo limit: Int) throws -> [Activity] {
        let results = try activities.aggregate([
            .geoNear(options: GeoNearOptions(
                near: Point(coordinate: Position(first: coordinates.longitude, second: coordinates.latitude)),
                spherical: true,
                distanceField: "distance",
                limit: try activities.count(),
                query: query
            )),
            .sort(sort),
            .skip(skip),
            .limit(max(limit, 1)), // Limit must be > 0.
            // Denormalize `host`.
            .lookup(from: users, localField: "host", foreignField: "_id", as: "host"),
            .unwind("$host"),
            // Denormalize `game`.
            .lookup(from: games, localField: "game", foreignField: "_id", as: "game"),
            .unwind("$game", preserveNullAndEmptyArrays: true)
        ])
        return try results.compactMap {
            // Here we denormalize `registrations[i].player`.
            // This is quite tricky to do in an aggregation pipeline,
            // so we use additional queries instead.
            var document = $0
            guard let registrations = Array(document["registrations"])?.compactMap(Document.init) else {
                throw log(BSONError.missingField(name: "registrations"))
            }
            for (index, registration) in registrations.enumerated() {
                guard let id = Int(registration["player"]),
                      let player = try user(withID: id) else {
                    throw log(BSONError.missingField(name: "player"))
                }
                document["registrations"][index]["player"] = player.document
            }
            return try Activity(document)
        }
    }
    
    /**
     Looks up the activity with the given ID in the database.
     
     - Returns: An activity, or `nil` if there was no activity with this ID.
     */
    func activity(withID id: Int, measuredFrom coordinates: Coordinates) throws -> Activity? {
        let results = try activities(matching: ["_id": id],
                                     measuredFrom: coordinates,
                                     sortedBy: ["creationDate": .descending],
                                     skipping: 0, limitedTo: 1)
        return results.first
    }
    
    /**
     Returns the number of visible activities.
     
     An activity is visible if its date is within the 30-day window and it isn't cancelled.
     
     - Parameter from: The start of the window. Default: the current date and time.
     */
    func numberOfActivities(inWindowFrom date: Date = Date()) throws -> Int {
        return try activities.count(["date": ["$gt": date, "$lt": date.adding30Days],
                                     "isCancelled": false])
    }
    
    /**
     Returns all visible activities, sorted by the date on which they appeared, in descending order.
     
     This date is usually the creation date, but for activities that were created before they became visible,
     it is the date on which they became visible.
     */
    func newestActivities(inWindowFrom date: Date = Date(), measuredFrom coordinates: Coordinates) throws -> [Activity] {
        func visibilityDate(for activity: Activity) -> Date {
            if activity.creationDate < activity.date.subtracting30Days {
                return activity.date.subtracting30Days
            } else {
                return activity.creationDate
            }
        }
        
        let results = try activities(matching: ["date": ["$gt": date, "$lt": date.adding30Days],
                                                "isCancelled": false],
                                     measuredFrom: coordinates,
                                     sortedBy: ["creationDate": .descending],
                                     skipping: 0, limitedTo: .max)
        return results.sorted { visibilityDate(for: $0) > visibilityDate(for: $1) }
    }
    
    /**
     Returns all visible activities, sorted by date in ascending order.
     */
    func upcomingActivities(inWindowFrom date: Date = Date(), measuredFrom coordinates: Coordinates) throws -> [Activity] {
        return try activities(matching: ["date": ["$gt": date, "$lt": date.adding30Days],
                                         "isCancelled": false],
                              measuredFrom: coordinates,
                              sortedBy: ["date": .ascending, "distance": .ascending],
                              skipping: 0, limitedTo: .max)
    }
    
    /**
     Returns all visible activities, sorted by distance to the given user in ascending order.
     */
    func activitiesNear(user: User, inWindowFrom date: Date = Date()) throws -> [Activity] {
        guard let coordinates = user.location?.coordinates else {
            throw log(ServerError.invalidState)
        }
        return try activities(matching: ["date": ["$gt": date, "$lt": date.adding30Days],
                                         "isCancelled": false],
                              measuredFrom: coordinates,
                              sortedBy: ["distance": .ascending, "date": .ascending],
                              skipping: 0, limitedTo: .max)
    }
    
    /**
     Returns the hosts of whom the given player has joined an activity in the 30-day window.
     
     This list can contain duplicates if the player has joined multiple activities of the same host.
     It is used to determine whether a player's registration should be automatically approved.
     */
    func hostsJoined(by player: User, inWindowFrom date: Date = Date()) throws -> [User] {
        guard let id = player.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let results = try activities(matching: ["registrations": ["$elemMatch": ["player": id,
                                                                                 "isApproved": true,
                                                                                 "isCancelled": false]],
                                                "date": ["$gt": date, "$lt": date.adding30Days],
                                                "isCancelled": false],
                                     measuredFrom: player.location?.coordinates ?? .default,
                                     sortedBy: ["date": .ascending],
                                     skipping: 0, limitedTo: .max)
        return results.map { $0.host }
    }
    
    /**
     Returns all activities hosted by the given user.
     
     This includes all activities that aren't cancelled and are less than 24 hours in the past.
     Results are sorted by date in ascending order.
     */
    func activities(hostedBy host: User) throws -> [Activity] {
        guard let id = host.id else {
            throw log(ServerError.unpersistedEntity)
        }
        return try activities(matching: ["host": id,
                                         "date": ["$gt": Date().previous],
                                         "isCancelled": false],
                              measuredFrom: .default,
                              sortedBy: ["date": .ascending],
                              skipping: 0, limitedTo: .max)
    }
    
    /**
     Returns all activities joined by the given user.
     
     This includes all activities that aren't cancelled and are less than 24 hours in the past.
     Results are sorted by date in ascending order.
     */
    func activities(joinedBy player: User) throws -> [Activity] {
        guard let id = player.id else {
            throw log(ServerError.unpersistedEntity)
        }
        return try activities(matching: ["registrations": ["$elemMatch": ["player": id,
                                                                          "isApproved": true,
                                                                          "isCancelled": false]],
                                         "date": ["$gt": Date().previous],
                                         "isCancelled": false],
                              measuredFrom: player.location?.coordinates ?? .default,
                              sortedBy: ["date": .ascending],
                              skipping: 0, limitedTo: .max)
    }

    /**
     Updates the given activity in the database.
     
     - Throws: ServerError.unpersistedEntity if the activity hasn't been persisted yet.
               Use `add(_:)` to add new actitivies to the database.
     */
    func update(_ activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        try activities.update(["_id": id], to: activity.document)
    }
}
