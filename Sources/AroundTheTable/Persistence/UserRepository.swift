/**
 Persistence methods related to users.
 */
extension Persistence {
    
    /**
     Adds a new user to the database.
     
     - Throws: ServerError.persistedEntity if the user already has an ID.
               Use `update(_:)` to update an existing user.
     */
    func add(_ user: User) throws {
        guard user.id == nil else {
            throw log(ServerError.persistedEntity)
        }
        user.id = try nextID(for: users)
        try users.insert(user.document)
    }
    
    /**
     Looks up the user with the given ID in the database.
     
     - Returns: A user, or `nil` if there was no user with this ID.
     */
    func user(withID id: Int) throws -> User? {
        return try User(users.findOne(["_id": id]))
    }
    
    /**
     Updates the given user in the database.
     
     - Throws: ServerError.unpersistedEntity if the user hasn't been persisted yet.
               Use `add(_:)` to add new users to the database.
     */
    func update(_ user: User) throws {
        guard let id = user.id else {
            throw log(ServerError.unpersistedEntity)
        }
        try users.update(["_id": id], to: user.document)
    }
}
