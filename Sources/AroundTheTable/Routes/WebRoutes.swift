import Credentials
import Kitura

extension Routes {
    
    /**
     Registers the web routes on the given router.
     */
    func configureWebRoutes(using router: Router, credentials: Credentials) {
        
        // Root pages.
        router.get("home", handler: home)
        router.get("faq", handler: faq)
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
     Shows the FAQ.
     */
    private func faq(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("faq", with: base, forKey: "base")
        next()
    }
    
    /**
     Shows the current activities.
     */
    private func activities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let view = request.queryParameters["view"] ?? "list"
        let sort = request.queryParameters["sort"] ?? "new"
        guard ["grid", "list"].contains(view) && ["new", "upcoming", "near-me"].contains(sort) else {
            response.status(.badRequest)
            return next()
        }
        let user = try authenticatedUser(for: request)
        let coordinates = user?.location?.coordinates ?? .default
        let activities: [Activity]
        switch sort {
        case "new":
            activities = try persistence.newestActivities(notHostedBy: user, measuredFrom: coordinates, startingFrom: 0, limitedTo: .max)
        case "upcoming":
            activities = try persistence.upcomingActivities(notHostedBy: user, measuredFrom: coordinates, startingFrom: 0, limitedTo: .max)
        case "near-me":
            activities = user?.location != nil ? try persistence.activitiesNear(user: user!, startingFrom: 0, limitedTo: .max) : []
        default:
            throw log(ServerError.invalidState)
        }
        let base = try baseViewModel(for: request)
        try response.render("activities-\(view)", with: ActivitiesViewModel(base: base, sort: sort, activities: activities))
        next()
    }
}
