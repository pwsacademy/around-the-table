import Configuration
import CloudFoundryEnv
import Foundation
import MongoKitten

/**
 This class represents the persistence layer.
 It holds a database connection and provides access to the database's collections.
 
 The actual persistence operations are provided by repositories.
 These repositories aren't implemented as types because they don't require any state.
 They consist entirely of functions, which is why they're implemented as extensions on this class.
 */
public class Persistence {
    
    private var database: Database
    
    /// The `activities` collection.
    let activities: MongoKitten.Collection
    
    /// The `conversations` collection.
    let conversations: MongoKitten.Collection
    
    /// The `games` collection.
    let games: MongoKitten.Collection
    
    /// The `users` collection.
    let users: MongoKitten.Collection
    
    /**
     Initializes the persistence layer and connects to the database.
     
     If **ATT.DATABASE.SERVICE** service is set, it will be used.
     If not, **ATT.DATABASE.URI** will be used.
     */
    public init() throws {
        let configuration = ConfigurationManager().load(.environmentVariables)
        var settings: ClientSettings
        // Check if a service is set and if so, use it.
        if let service = Settings.database.service,
           let credentials = configuration.getServiceCreds(spec: service),
           let uri = credentials["uri"] as? String {
            settings = try ClientSettings(uri)
            // Load the certificate authority required to connect to the Compose for MongoDB service on Bluemix.
            settings.sslSettings = SSLSettings(enabled: true,
                                               CAFilePath: ConfigurationManager.BasePath.project.path + "/Configuration/CAFile")
        } else {
            settings = try ClientSettings(Settings.database.uri)
        }
        let server = try Server(settings)
        database = server[Settings.database.name]
        activities = database["activities"]
        conversations = database["conversations"]
        games = database["games"]
        users = database["users"]
    }
}
