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
        guard let id = try activities.insert(activity.document) as? ObjectId else {
            throw log(BSONError.missingField(name: "_id"))
        }
        activity.id = id
    }
    
    /**
     Looks up activities using a `geoNear` query and sets the `distance` property.
     
     All other methods should call this method to ensure activities are properly loaded.
     */
    private func activities(matching query: Query,
                            measuredFrom coordinates: Coordinates,
                            sortedBy sort: Sort,
                            startingFrom start: Int,
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
            .skip(start),
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
                guard let id = ObjectId(registration["player"]),
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
    func activity(with id: ObjectId, measuredFrom coordinates: Coordinates) throws -> Activity? {
        let results = try activities(matching: ["_id": id],
                                     measuredFrom: coordinates,
                                     sortedBy: ["creationDate": .descending],
                                     startingFrom: 0,
                                     limitedTo: 1)
        return results.first
    }
    
    /**
     Returns the number of available activities.
     
     An activity is available if the deadline for registration hasn't passed and the activity isn't cancelled.
     
     - Parameter host: Activities hosted by this user will be excluded from the result.
     */
    func numberOfActivities(notHostedBy host: User? = nil) throws -> Int {
        if let host = host {
            guard let id = host.id else {
                throw log(ServerError.unpersistedEntity)
            }
            return try activities.count(["host": ["$ne": id], "deadline": ["$gt": Date()], "isCancelled": false])
        } else {
            return try activities.count(["deadline": ["$gt": Date()], "isCancelled": false])
        }
    }
    
    /**
     Returns all available activities, sorted by creation date in descending order.
     
     An activity is available if the deadline for registration hasn't passed and the activity isn't cancelled.
     
     - Parameter host: Activities hosted by this user will be excluded from the result.
     - Parameter startingFrom: The number of results to skip.
     - Parameter limitedTo: The maximum number of results to return.
     */
    func newestActivities(notHostedBy host: User? = nil, measuredFrom coordinates: Coordinates,
                          startingFrom start: Int, limitedTo limit: Int) throws -> [Activity] {
        let query: Query
        if let host = host {
            guard let id = host.id else {
                throw log(ServerError.unpersistedEntity)
            }
            query = ["host": ["$ne": id], "deadline": ["$gt": Date()], "isCancelled": false]
        } else {
            query = ["deadline": ["$gt": Date()], "isCancelled": false]
        }
        return try activities(matching: query,
                              measuredFrom: coordinates,
                              sortedBy: ["creationDate": .descending],
                              startingFrom: start, limitedTo: limit)
    }
    
    /**
     Returns all available activities, sorted by date in ascending order.
     
     An activity is available if the deadline for registration hasn't passed and the activity isn't cancelled.
     
     - Parameter host: Activities hosted by this user will be excluded from the result.
     - Parameter startingFrom: The number of results to skip.
     - Parameter limitedTo: The maximum number of results to return.
     */
    func upcomingActivities(notHostedBy host: User? = nil, measuredFrom coordinates: Coordinates,
                            startingFrom start: Int, limitedTo limit: Int) throws -> [Activity] {
        let query: Query
        if let host = host {
            guard let id = host.id else {
                throw log(ServerError.unpersistedEntity)
            }
            query = ["host": ["$ne": id], "deadline": ["$gt": Date()], "isCancelled": false]
        } else {
            query = ["deadline": ["$gt": Date()], "isCancelled": false]
        }
        return try activities(matching: query,
                              measuredFrom: coordinates,
                              sortedBy: ["date": .ascending, "distance": .ascending],
                              startingFrom: start, limitedTo: limit)
    }
    
    /**
     Returns all available activities, sorted by distance to the given user in ascending order.
     
     An activity is available if the deadline for registration hasn't passed and the activity isn't cancelled.
     Activities hosted by the given user are excluded from the result.
     
     - Parameter startingFrom: The number of results to skip.
     - Parameter limitedTo: The maximum number of results to return.
     - Throws: ServerError.invalidState if the given user doesn't have a saved location.
     */
    func activitiesNear(user: User, startingFrom start: Int, limitedTo limit: Int) throws -> [Activity] {
        guard let id = user.id else {
            throw log(ServerError.unpersistedEntity)
        }
        guard let coordinates = user.location?.coordinates else {
            throw log(ServerError.invalidState)
        }
        return try activities(matching: ["host": ["$ne": id], "deadline": ["$gt": Date()], "isCancelled": false],
                              measuredFrom: coordinates,
                              sortedBy: ["distance": .ascending, "date": .ascending],
                              startingFrom: start, limitedTo: limit)
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
        let yesterday = Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: Date())!
        return try activities(matching: ["host": id, "date": ["$gt": yesterday], "isCancelled": false],
                              measuredFrom: .default,
                              sortedBy: ["date": .ascending],
                              startingFrom: 0, limitedTo: .max)
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
        let yesterday = Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: Date())!
        return try activities(matching: ["registrations": ["$elemMatch": ["player": id,
                                                                          "isApproved": true,
                                                                          "isCancelled": false]],
                                         "date": ["$gt": yesterday],
                                         "isCancelled": false],
                              measuredFrom: player.location?.coordinates ?? .default,
                              sortedBy: ["date": .ascending],
                              startingFrom: 0, limitedTo: .max)
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
