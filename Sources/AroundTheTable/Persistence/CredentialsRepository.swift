import Cryptor
import MongoKitten

/**
 Persistence methods related to authentication credentials.
 
 For general information on password hashing, see https://crackstation.net/hashing-security.htm
 */
extension Persistence {
    
    /**
     Adds an email credential to a user.
     
     If the user already had an email credential, the previous one will be overwritten.
     So this method can be used to change a user's email address and/or password.
     
     - Throws: ServerError.conflict if the email address is already used by another user.
     */
    func addEmailCredential(for user: User, email: String, password: String) throws {
        guard let id = user.id else {
            throw log(ServerError.unpersistedEntity)
        }
        // Make sure the email address isn't already used by another user.
        guard try userWith(email: email) ?? user == user else {
            throw log(ServerError.conflict)
        }
        let salt = CryptoUtils.hexString(from: try Random.generate(byteCount: 32))
        let hash = try encrypt(password: password, salt: salt)
        var credential = try credentials.findOne(["_id": id]) ?? ["_id": id]
        credential["email"] = email
        credential["hash"] = hash
        credential["salt"] = salt
        try credentials.update(["_id": id], to: credential, upserting: true)
    }
    
    /**
     Adds a Facebook credential to a user.
     
     If the user already had a Facebook credential, the previous one will be overwritten.
     
     - Throws: ServerError.conflict if the Facebook ID is already used by another user.
     */
    func addFacebookCredential(for user: User, facebookID: String) throws {
        guard let id = user.id else {
            throw log(ServerError.unpersistedEntity)
        }
        // Make sure the Facebook ID isn't already used.
        guard try userWith(facebookID: facebookID) == nil else {
            throw log(ServerError.conflict)
        }
        var credential = try credentials.findOne(["_id": id]) ?? ["_id": id]
        credential["facebook"] = facebookID
        try credentials.update(["_id": id], to: credential, upserting: true)
    }
    
    /**
     Returns the user with the given email address or `nil` if there is no user with this email address.
     */
    func userWith(email: String) throws -> User? {
        guard let credential = try credentials.findOne(["email": email]),
              let id = ObjectId(credential["_id"]) else {
            return nil
        }
        return try user(withID: id)
    }
    
    /**
     Returns the user with the given email credential or `nil` if there is no user with this email address,
     or the password is incorrect.
     */
    func userWith(email: String, password: String) throws -> User? {
        guard let credential = try credentials.findOne(["email": email]),
              let id = ObjectId(credential["_id"]),
              let hash = String(credential["hash"]),
              let salt = String(credential["salt"]) else {
            return nil
        }
        guard try encrypt(password: password, salt: salt) == hash else {
            return nil
        }
        return try user(withID: id)
    }
    
    /**
     Returns the user with the given Facebook ID or `nil` if there is no user with this Facebook ID.
     */
    func userWith(facebookID: String) throws -> User? {
        guard let credential = try credentials.findOne(["facebook": facebookID]),
              let id = ObjectId(credential["_id"]) else {
            return nil
        }
        return try user(withID: id)
    }
    
    private func encrypt(password: String, salt: String) throws -> String {
        let hash = try PBKDF.deriveKey(fromPassword: password, salt: salt, prf: .sha256, rounds: 100_000, derivedKeyLength: 32)
        return CryptoUtils.hexString(from: hash)
    }
}
