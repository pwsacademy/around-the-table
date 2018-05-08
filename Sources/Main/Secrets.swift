import Configuration

/*
 Typesafe wrapper around `secrets.json`.
 */
enum Secrets {
    
    private static let secrets = ConfigurationManager().load(file: "Configuration/old/secrets.json", relativeFrom: .project)
    
    // Used to encrypt the session ID cookie.
    static let sessionSecret = secrets["sessionSecret"] as! String
    
    // Used to authenticate with Facebook for Web Login.
    static let facebookAppSecret = secrets["facebookAppSecret"] as! String
    
    // Used to authenticate with Google for Maps and Places.
    static let googleAPIKey = secrets["googleAPIKey"] as! String
}
