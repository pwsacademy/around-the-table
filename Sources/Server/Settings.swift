import Configuration
import Foundation

/*
 Typesafe wrapper around `settings.json`.
 */
enum Settings {
    
    private static let configuration = ConfigurationManager().load(file: "Configuration/settings.json", relativeFrom: .project)
    
    /*
     Configures a custom domain name. 
     If a custom domain name is present, the app will forward all requests to this custom domain.
     This forwarding is necessary as the app uses session cookies, which are attached to a particular domain.
     This setting does not affect how the app behaves when running on localhost.
     */
    static let customDomainName = configuration["settings:customDomainName"] as? String
    
    // Default pictures.
    static let defaultGamePicture = configuration["settings:defaultGamePicture"] as! String
    static let defaultGameThumbnail = configuration["settings:defaultGameThumbnail"] as! String
    static let defaultProfilePicture = configuration["settings:defaultProfilePicture"] as! String
    
    // Used to constrain the results returned by the Google Places autocompletion field.
    static let countries = configuration["settings:countries"] as! [String]
    // Used to select the views to render and to localize anything that needs localization (e.g. dates).
    static let locale = configuration["settings:locale"] as! String
    // Used to display dates in the correct time zone.
    static let timeZone = TimeZone(identifier: configuration["settings:timeZone"] as! String) ?? TimeZone.current
    
    // Used to calculate distances when the user has disabled geolocation.
    enum defaultCoordinates {
        
        static let latitude = configuration["settings:defaultCoordinates:latitude"] as! Double
        static let longitude = configuration["settings:defaultCoordinates:longitude"] as! Double
    }
    
    enum database {
        
        // The name by which the Compose for MongoDB service is connected to your Bluemix app.
        static let bluemixService = configuration["settings:database:bluemixService"] as! String
        // The URI of your MongoDB database when running on localhost.
        static let localURI = configuration["settings:database:localURI"] as! String
        // The name of your database.
        static let name = configuration["settings:database:name"] as! String
    }
}
