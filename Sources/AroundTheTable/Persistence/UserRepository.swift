/**
 Persistence methods related to users.
 */
extension Persistence {
    
    /**
     Adds a new user to the database.
     
     - Throws: ServerError.persistedEntity if a user with this ID already exists.
     */
    func add(_ user: User) throws {
        guard try self.user(withID: user.id) == nil else {
            throw log(ServerError.persistedEntity)
        }
        try collection(.users).insert(user.document)
    }
    
    /**
     Looks up the user with the given ID in the database.
     
     - Returns: A user, or `nil` if there was no user with this ID.
     */
    func user(withID id: String) throws -> User? {
        return try User(collection(.users).findOne(["_id": id]))
    }
    
    /**
     Updates the given user in the database.
     */
    func update(_ user: User) throws {
        try collection(.users).update(["_id": user.id], to: user.document)
    }
}
