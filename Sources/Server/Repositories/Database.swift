import Configuration
import MongoKitten

/*
 Database instances can safely be reused and shared so we store only a single instance.
 */
private var database: Database?

/*
 Returns the Database instance.
 Creates it if necessary.
 */
private func getDatabase() throws -> Database {
    guard database == nil else {
        return database!
    }
    let localURI = Settings.database.localURI
    let bluemixService = Settings.database.bluemixService
    let uri = configuration.getServiceCreds(spec: bluemixService)?["uri"] as? String ?? localURI
    var settings = try ClientSettings(uri)
    if uri != localURI {
        // Load the certificate authority required to connect to the Compose for MongoDB service on Bluemix.
        settings.sslSettings = SSLSettings(enabled: true, CAFilePath: ConfigurationManager.BasePath.project.path + "/Configuration/CAFile")
    }
    let server = try Server(settings)
    database = server[Settings.database.name]
    return database!
}

/*
 Typesafe collection names.
 */
enum CollectionName: String {
    
    case users = "users"
    case gameData = "gameData"
    case games = "games"
    case messages = "messages"
    case requests = "requests"
}

/*
 Collection instances can safely be reused and shared so we store created instances in a dictionary.
 */
private var collections: [CollectionName: MongoKitten.Collection] = [:]

/*
 Looks up the Collection instance for the collection with the given name.
 Creates it if necessary.
 */
func collection(_ name: CollectionName) throws -> MongoKitten.Collection {
    let db = try database ?? getDatabase()
    if let collection = collections[name] {
        return collection
    } else {
        let collection = db[name.rawValue]
        collections[name] = collection
        return collection
    }
}
