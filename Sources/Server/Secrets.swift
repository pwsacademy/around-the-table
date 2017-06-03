import Configuration

/*
 Typesafe wrapper around `secrets.json`.
 */
enum Secrets {
    
    private static let configuration = ConfigurationManager().load(file: "Configuration/secrets.json", relativeFrom: .project)
    
    // Used to encrypt the session ID cookie.
    static let sessionSecret = configuration["secrets:sessionSecret"] as! String
    
    // Used to authenticate with Facebook for Web Login.
    static let facebookAppID = configuration["secrets:facebookAppID"] as! String
    static let facebookAppSecret = configuration["secrets:facebookAppSecret"] as! String
    
    // Used to authenticate with Google for Maps and Places.
    static let googleAPIKey = configuration["secrets:googleAPIKey"] as! String
}
