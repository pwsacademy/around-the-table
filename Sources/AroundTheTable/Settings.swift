import CloudFoundryEnv
import Configuration
import Foundation

/**
 Provides typesafe access to settings.
 
 Settings come from two places:
 
 1. **settings.json**. This file contains default values and settings suitable for a development environment.
 2. Environment variables. These can be used to define secrets and to override settings.
 
 To override a setting with an environment variable, use a double underscore (`__`) as a path separator.
 For example: **ATT.DATABASE.NAME** can be overridden by an environment variable named **ATT__DATABASE__NAME**.
 */
enum Settings {
    
    /// Settings are loaded using a `ConfigurationManager`.
    /// Environment variables are loaded last so they override values in **settings.json**.
    private static let settings = ConfigurationManager()
        .load(file: "Configuration/settings.json", relativeFrom: .project)
        .load(.environmentVariables)
    
    /// Configures a custom domain name.
    /// If a custom domain name is configured, the app will forward all requests to this custom domain.
    /// This forwarding is necessary as the app uses session cookies, which are attached to a particular domain.
    /// This setting is optional and is normally only used when running in production.
    static let customDomain = settings["ATT:CUSTOM_DOMAIN"] as? String
    
    /// The current base URL (protocol, host and port).
    /// If a custom domain is configured, it will be returned, prefixed with https.
    /// This is a computed property, you cannot set or override it.
    static let url: String = {
        if let customDomain = Settings.customDomain {
            return "https://\(customDomain)"
        } else {
            return settings.url
        }
    }()
    
    /**
     Settings related to Cloud Object Storage.
     */
    enum cloudObjectStorage {
        
        /// The API key that should be used to request an OAuth token.
        /// This setting is optional and should be provided by an environment variable.
        /// If no API key is provided, cloud object storage will not be used.
        static let apiKey = settings["ATT:COS:API_KEY"] as? String
        
        /// The complete URL of the bucket where the images should be stored.
        static let bucketURL = settings["ATT:COS:BUCKET_URL"] as? String
    }
    
    /**
     Database configuration.
     */
    enum database {
        
        /// The name by which the Compose for MongoDB service is connected.
        /// This setting is optional and is only used when running on Bluemix.
        /// When it is defined, it replaces **ATT.DATABASE.URI**.
        static let service = settings["ATT:DATABASE:SERVICE"] as? String
        
        /// The URI of the MongoDB server.
        static let uri = settings["ATT:DATABASE:URI"] as! String
        
        /// The name of the database.
        static let name = settings["ATT:DATABASE:NAME"] as! String
    }
    
    /**
     A default location that is used to calculate distances when a user has not specified his/her location.
     
     This location is also available as `Coordinates.default`.
     */
    enum defaultCoordinates {
        
        static let latitude = settings["ATT:DEFAULT_COORDINATES:LATITUDE"] as! Double
        static let longitude = settings["ATT:DEFAULT_COORDINATES:LONGITUDE"] as! Double
    }

    /// The default picture for a game.
    static let defaultGamePicture = settings["ATT:DEFAULT_GAME_PICTURE"] as! String
    
    /// The default thumbnail for a game.
    static let defaultGameThumbnail = settings["ATT:DEFAULT_GAME_THUMBNAIL"] as! String
    
    /// The default profile picture for a user.
    static let defaultProfilePicture = settings["ATT:DEFAULT_PROFILE_PICTURE"] as! String
    
    /// Whether dummy accounts are enabled.
    static let areDummiesEnabled = (settings["ATT:ENABLE_DUMMIES"] as? String) == "true"
    
    /**
     Settings related to Facebook Web Login.
     */
    enum facebook {
        
        /// The Facebook app ID.
        static let app = settings["ATT:FACEBOOK:APP"] as! String
        
        /// The Facebook app secret.
        /// This should be provided by an environment variable.
        static let secret = settings["ATT:FACEBOOK:SECRET"] as! String
    }
    
    /**
     Settings related to Google.
     */
    enum google {
        
        /// The countries to which you want to limit Google Maps address autocompletion results.
        static let countries = settings["ATT:GOOGLE:COUNTRIES"] as! [String]
        
        /// The Google Maps API key.
        /// Note that this isn't really a secret, as it is visible in the source code.
        /// Hence, it should be limited to your domain so it can't be misused.
        /// A default value is provided in **settings.json** for use during development.
        static let secret = settings["ATT:GOOGLE:SECRET"] as! String
    }
    
    /// The locale used to localize anything that needs it (e.g. views, messages, dates, ...).
    static let locale = settings["ATT:LOCALE"] as! String
        
    /// The key used to encrypt the session cookie.
    /// A default value is provided in **settings.json** for use during development.
    static let sessionSecret = settings["ATT:SESSION_SECRET"] as! String
    
    /// The time zone used to display dates.
    static let timeZone = TimeZone(identifier: settings["ATT:TIME_ZONE"] as! String) ?? TimeZone.current
}
