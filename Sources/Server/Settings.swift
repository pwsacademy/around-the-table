import Configuration
import Foundation

/*
 Typesafe wrapper around `settings.json`.
 */
enum Settings {
    
    private static let settings = ConfigurationManager().load(file: "Configuration/settings.json", relativeFrom: .project)
    
    /*
     Configures a custom domain name. 
     If a custom domain name is present, the app will forward all requests to this custom domain.
     This forwarding is necessary as the app uses session cookies, which are attached to a particular domain.
     This setting does not affect how the app behaves when running on localhost.
     It is also ignored when deploying to a test server.
     */
    static let customDomainName = configuration["TEST"] == nil ? settings["settings:customDomainName"] as? String : nil
    
    // Default pictures.
    static let defaultGamePicture = settings["settings:defaultGamePicture"] as! String
    static let defaultGameThumbnail = settings["settings:defaultGameThumbnail"] as! String
    static let defaultProfilePicture = settings["settings:defaultProfilePicture"] as! String
    
    // Used to constrain the results returned by the Google Places autocompletion field.
    static let countries = settings["settings:countries"] as! [String]
    // Used to select the views to render and to localize anything that needs localization (e.g. dates).
    static let locale = settings["settings:locale"] as! String
    // Used to display dates in the correct time zone.
    static let timeZone = TimeZone(identifier: settings["settings:timeZone"] as! String) ?? TimeZone.current
    
    // Used to calculate distances when the user has disabled geolocation.
    enum defaultCoordinates {
        
        static let latitude = settings["settings:defaultCoordinates:latitude"] as! Double
        static let longitude = settings["settings:defaultCoordinates:longitude"] as! Double
    }
    
    enum database {
        
        // The name by which the Compose for MongoDB service is connected to your Bluemix app.
        static let bluemixService = settings["settings:database:bluemixService"] as! String
        // The URI of your MongoDB database when running on localhost.
        static let localURI = settings["settings:database:localURI"] as! String
        // The name of your database. When deploying to a test server, a test database is used.
        static let name = configuration["TEST"] == nil ?
            settings["settings:database:name"] as! String :
            settings["settings:database:test"] as! String
    }
    
    /*
     Facebook group for the site.
     If set, games created on the site will be announced in this group.
     */
    static let facebookGroupID = settings["settings:facebookGroupID"] as? String
}
