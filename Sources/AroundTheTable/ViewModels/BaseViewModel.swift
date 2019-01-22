import HTMLEntities

/**
 View model for **base.stencil**.
 */
struct BaseViewModel: Codable {

    struct UserViewModel: Codable {
        
        let id: Int
        let name: String
        let picture: String
        let location: Location?
        
        init(_ user: User) throws {
            guard let id = user.id else {
                throw log(ServerError.unpersistedEntity)
            }
            self.id = id
            self.name = user.name.htmlEscape()
            self.picture = user.picture?.absoluteString ?? Settings.defaultProfilePicture
            self.location = user.location
        }
    }
    
    /// The user who is currently signed in.
    let user: UserViewModel?
    
    /// The number of unread notifications for the current user.
    let unreadNotificationCount: Int
    
    /// The number of unread messages for the current user.
    let unreadMessageCount: Int
    
    struct SponsorViewModel: Codable {
        
        let name: String
        let picture: String
        let link: String
        
        init(_ sponsor: Sponsor) {
            self.name = sponsor.name
            self.picture = sponsor.picture.absoluteString
            self.link = sponsor.link.absoluteString
        }
    }
    
    /// A random sponsor
    let sponsor: SponsorViewModel?
    
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
    init(user: User?, unreadNotificationCount: Int, unreadMessageCount: Int, sponsor: Sponsor?, requestURL: String) throws {
        if let user = user {
            self.user = try UserViewModel(user)
        } else {
            self.user = nil
        }
        self.unreadNotificationCount = unreadNotificationCount
        self.unreadMessageCount = unreadMessageCount
        if let sponsor = sponsor {
            self.sponsor = SponsorViewModel(sponsor)
        } else {
            self.sponsor = nil
        }
        self.facebook = Facebook(app: Settings.facebook.app)
        self.opengraph = OpenGraph(url: requestURL, image: "\(Settings.url)/public/img/opengraph.jpg")
        coordinates = .default
        google = Google(key: Settings.google.secret,
                        // Builds a JSON array
                        countries: "[\(Settings.google.countries.map { "\"\($0)\"" }.joined(separator: ", "))]")
    }
}
