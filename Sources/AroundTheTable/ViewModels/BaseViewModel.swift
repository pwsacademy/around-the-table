/**
 View model for **base.stencil**.
 */
struct BaseViewModel: Codable {

    struct UserViewModel: Codable {
        
        let id: String
        let name: String
        let picture: String
        let location: Location?
        
        init(_ user: User) {
            self.id = user.id
            self.name = user.name
            self.picture = user.picture?.absoluteString ?? Settings.defaultProfilePicture
            self.location = user.location
        }
    }
    
    /// The user who is currently signed in.
    let user: UserViewModel?
    
    /// The number of unread messages for the current user.
    let unreadMessageCount: Int
    
    struct Facebook: Codable {
        let app: String
    }
    
    /// Facebook settings.
    let facebook: Facebook
    
    struct OpenGraph: Codable {
        let url: String
        let image: String
    }
    
    /// OpenGraph metadata.
    let opengraph: OpenGraph
    
    /// The apps' default coordinates.
    let coordinates: Coordinates
    
    struct Google: Codable {
        let key: String
        let countries: String
    }
    
    /// Google Maps settings.
    let google: Google
    
    /**
     Initializes a `BaseViewModel` using the given user and request URL.
     */
    init(user: User?, unreadMessageCount: Int, requestURL: String) {
        if let user = user {
            self.user = UserViewModel(user)
        } else {
            self.user = nil
        }
        self.unreadMessageCount = unreadMessageCount
        self.facebook = Facebook(app: Settings.facebook.app)
        self.opengraph = OpenGraph(url: requestURL, image: "\(Settings.url)/public/img/opengraph.jpg")
        coordinates = .default
        google = Google(key: Settings.secrets.google,
                        // Builds a JSON array
                        countries: "[\(Settings.countries.map { "\"\($0)\"" }.joined(separator: ", "))]")
    }
}
