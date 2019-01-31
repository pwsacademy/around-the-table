import Credentials
import Kitura
import KituraSession

extension Routes {
    
    /**
     Registers the web routes on the given router.
     */
    func configureWebRoutes(using router: Router, credentials: Credentials) {
        
        // Root pages.
        router.get("home", handler: home)
        router.get("about", handler: about)
        router.get("sponsors", handler: sponsors)
        router.get("faq", handler: faq)
        router.get("rules", handler: rules)
        router.get("activities", handler: activities)
        
        // Delegate the host, activity and user categories to subrouters.
        configureWebHostRoutes(using: router.route("host"), credentials: credentials)
        configureWebActivityRoutes(using: router.route("activity"), credentials: credentials)
        configureWebUserRoutes(using: router.route("user"), credentials: credentials)
    }
    
    /**
     Shows the home page.
     */
    private func home(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("home", with: base, forKey: "base")
        next()
    }
    
    /**
     Shows the about page.
     */
    private func about(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("about", with: base, forKey: "base")
        next()
    }
    
    /**
     Shows the sponsors page.
     */
    private func sponsors(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        let sponsors = try persistence.allSponsors()
        try response.render("sponsors", with: SponsorsViewModel(base: base, sponsors: sponsors))
        next()
    }
    
    /**
     Shows the FAQ.
     */
    private func faq(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("faq", with: base, forKey: "base")
        next()
    }
    
    /**
     Shows the site rules.
     */
    private func rules(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("rules", with: base, forKey: "base")
        next()
    }
    
    /**
     Shows the current activities.
     */
    private func activities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        let view: String
        if let viewParameter = request.queryParameters["view"] {
            // If a view is specified, it is stored in the user's session.
            view = viewParameter
            session["preferredActivitiesView"] = viewParameter
        } else {
            // If no view is specified, either the user's stored (last) view is used, or the default, list.
            view = session["preferredActivitiesView"] as? String ?? "list"
        }
        let sort: String
        if let sortParameter = request.queryParameters["sort"] {
            // If a sort is specified, it is stored in the user's session.
            sort = sortParameter
            session["preferredActivitiesSort"] = sortParameter
        } else {
            // If no sort is specified, either the user's stored (last) sort is used, or the default, new.
            sort = session["preferredActivitiesSort"] as? String ?? "new"
        }
        guard ["grid", "list"].contains(view) && ["new", "upcoming", "near-me"].contains(sort) else {
            response.status(.badRequest)
            return next()
        }
        let user = try authenticatedUser(for: request)
        let coordinates = user?.location?.coordinates ?? .default
        let activities: [Activity]
        switch sort {
        case "new":
            activities = try persistence.newestActivities(measuredFrom: coordinates)
        case "upcoming":
            activities = try persistence.upcomingActivities(measuredFrom: coordinates)
        case "near-me":
            activities = user?.location != nil ? try persistence.activitiesNear(user: user!) : []
        default:
            throw log(ServerError.invalidState)
        }
        let base = try baseViewModel(for: request)
        try response.render("activities-\(view)", with: ActivitiesViewModel(base: base, sort: sort, activities: activities, for: user))
        next()
    }
}
