import Credentials
import CredentialsFacebook
import Health
import Kitura
import KituraStencil
import KituraSession
import LoggerAPI
import Stencil

/**
 This class represents the routing layer.
 
 Routes are split into categories and configured via subrouters.
 Subrouters aren't implemented as types, they are simply methods, grouped into extensions.
 Every extension has one entry point that configures the routes in that extension.
 */
public class Routes {
    
    /// The persistence layer.
    let persistence: Persistence
    
    /// The notification service.
    let notificationService: NotificationService
    
    /// The health checker.
    private let health = Health()
    
    /**
     Initializes the routing layer.
     
     This does not create any routes.
     To set up routes, call `configure(using:)`.
     */
    public init(persistence: Persistence) {
        self.persistence = persistence
        notificationService = NotificationService(persistence: persistence)
    }
    
    /**
     Registers all of the application's routes on the given router.
     
     This method does global setup, then delegates to methods defined in extensions to configure the various routes.
     */
    public func configure(using router: Router) {
        
        // Configures Stencil.
        let stencil = Extension()
        StencilFilters.register(on: stencil)
        router.setDefault(templateEngine: StencilTemplateEngine(extension: stencil))
        router.viewsPath = "Views/\(Settings.locale)"
        
        // Enables forwarding.
        router.all(middleware: ForwardingMiddleware(domain: Settings.customDomain))
        
        // Registers a static file server.
        router.all("/public", middleware: StaticFileServer())
        
        // Creates a session and credentials middleware.
        let session = Session(secret: Settings.sessionSecret, cookie: [.maxAge(14 * 24 * 3600.0)])
        let credentials = makeCredentials()
        
        // Authentication routes.
        router.all("authentication", middleware: [session])
        configureAuthenticationRoutes(using: router.route("authentication"), credentials: credentials)
        
        // Web routes.
        router.all("web", middleware: session)
        configureWebRoutes(using: router.route("web"), credentials: credentials)
        
        // Home page.
        router.get("/") {
            request, response, next in
            try response.redirect("/web/home")
        }
        
        // Registers a health endpoint.
        router.get("health") {
            request, response, next in
            if self.health.status.state == .UP {
                try response.status(.OK).send(self.health.status).end()
            } else {
                try response.status(.serviceUnavailable).send(self.health.status).end()
            }
        }
        
        // Registers a global error handler.
        // This route should always be registered last!
        router.error(error)
    }
    
    /**
     Creates a `Credentials` middleware.
     
     This middleware redirects unauthenticated users to the welcome page.
     From there, they can either sign in with Facebook or an email credential.
     */
    private func makeCredentials() -> Credentials {
        let credentials = Credentials()
        let facebook = CredentialsFacebook(clientId: Settings.facebook.app,
                                           clientSecret: Settings.facebook.secret,
                                           callbackUrl: "\(Settings.url)/authentication/facebook/callback",
                                           options: ["fields": "name,picture.type(large)", "scope": ["public_profile"]])
        credentials.register(plugin: facebook)
        credentials.options["failureRedirect"] = "/authentication/welcome"
        return credentials
    }
    
    /**
     The global error handler.
     
     Returns a 500 Internal Server Error for API requests.
     Renders an error page for web requests.
     */
    private func error(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        if let error = response.error {
            let message: String
            switch error {
            case let error as Loggable:
                message = error.message
            default:
                message = error.localizedDescription
            }
            if !(error is Loggable) {
                // Loggable errors should have already been logged.
                Log.error(message)
            }
            if request.originalURL.contains("/api/") {
                response.statusCode = .internalServerError
                response.send(message)
            } else {
                let base = try self.baseViewModel(for: request)
                try response.render("error", with: ErrorViewModel(base: base, message: message))
            }
        }
        next()
    }
}

/**
 Utility functions, used by several extensions.
 */
extension Routes {
    
    /**
     Returns the currently authenticated user.
     */
    func authenticatedUser(for request: RouterRequest) throws -> User? {
        guard let profile = request.userProfile else {
            return nil
        }
        let lookup = profile.provider == "Facebook" ? persistence.userWith(facebookID:) : persistence.userWith(email:)
        return try lookup(profile.id)
    }
    
    /**
     Creates a `BaseViewModel` for the given request.
     */
    func baseViewModel(for request: RouterRequest) throws -> BaseViewModel {
        let user = try authenticatedUser(for: request)
        let unreadMessageCount = user != nil ? try persistence.unreadMessageCount(for: user!) : 0
        return try BaseViewModel(user: user,
                                 unreadMessageCount: unreadMessageCount,
                                 sponsor: try persistence.randomSponsor(),
                                 requestURL: request.originalURL)
    }
}
