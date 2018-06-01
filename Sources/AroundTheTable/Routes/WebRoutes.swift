import Credentials
import Kitura

extension Routes {
    
    /**
     Registers the web routes on the given router.
     */
    func configureWeb(using router: Router, credentials: Credentials) {
        router.get("home", handler: home)
        router.get("faq", handler: faq)
        
        router.get("games", handler: activities)
        router.get("newest-games", handler: newestActivities)
        router.get("upcoming-games", handler: upcomingActivities)
        router.get("games-near-me", handler: activitiesNearMe)
        
        let authentication = AuthenticationMiddleware(persistence: persistence)
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
     Shows a selection of new activities, upcoming activities and activities near the user.
     */
    private func activities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let user: User?
        if let userID = request.userProfile?.id {
            guard let existingUser = try persistence.user(withID: userID) else {
                throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
            }
            user = existingUser
        } else {
            user = nil
        }
        let coordinates = user?.location?.coordinates ?? .default
        let newest = try persistence.newestActivities(notHostedBy: user, measuredFrom: coordinates, startingFrom: 0, limitedTo: 4)
        let upcoming = try persistence.upcomingActivities(notHostedBy: user, measuredFrom: coordinates, startingFrom: 0, limitedTo: 4)
        let closest = user?.location != nil ? try persistence.activitiesNear(user: user!, startingFrom: 0, limitedTo: 4) : []
        let base = try baseViewModel(for: request)
        try response.render("games", with: ActivitiesViewModel(base: base,
                                                               newest: newest,
                                                               upcoming: upcoming,
                                                               closest: closest))
        next()
    }
    
    /**
     Shows a paged list of activities, sorted by date of creation.
     */
    private func newestActivities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let pageString = request.queryParameters["page"],
              let page = Int(pageString) else {
            response.status(.badRequest)
            return next()
        }
        let user: User?
        if let userID = request.userProfile?.id {
            guard let existingUser = try persistence.user(withID: userID) else {
                throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
            }
            user = existingUser
        } else {
            user = nil
        }
        let coordinates = user?.location?.coordinates ?? .default
        let pageSize = 8
        let activities = try persistence.newestActivities(notHostedBy: user,
                                                          measuredFrom: coordinates,
                                                          startingFrom: page * pageSize,
                                                          limitedTo: pageSize)
        let remaining = try persistence.numberOfActivities(notHostedBy: user) - (page + 1) * pageSize
        let base = try baseViewModel(for: request)
        try response.render("games-page", with: ActivitiesPageViewModel(base: base,
                                                                        type: .newest,
                                                                        activities: activities,
                                                                        page: page,
                                                                        hasNextPage: remaining > 0))
        next()
    }
    
    /**
     Shows a paged list of activities, sorted by date.
     */
    private func upcomingActivities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let pageString = request.queryParameters["page"],
              let page = Int(pageString) else {
            response.status(.badRequest)
            return next()
        }
        let user: User?
        if let userID = request.userProfile?.id {
            guard let existingUser = try persistence.user(withID: userID) else {
                throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
            }
            user = existingUser
        } else {
            user = nil
        }
        let coordinates = user?.location?.coordinates ?? .default
        let pageSize = 8
        let activities = try persistence.upcomingActivities(notHostedBy: user,
                                                            measuredFrom: coordinates,
                                                            startingFrom: page * pageSize,
                                                            limitedTo: pageSize)
        let remaining = try persistence.numberOfActivities(notHostedBy: user) - (page + 1) * pageSize
        let base = try baseViewModel(for: request)
        try response.render("games-page", with: ActivitiesPageViewModel(base: base,
                                                                        type: .upcoming,
                                                                        activities: activities,
                                                                        page: page,
                                                                        hasNextPage: remaining > 0))
        next()
    }
    
    /**
     Shows a paged list of activities, sorted by distance to the user.
     */
    private func activitiesNearMe(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let pageString = request.queryParameters["page"],
              let page = Int(pageString) else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        guard let userID = request.userProfile?.id,
              let user = try persistence.user(withID: userID),
              user.location != nil else {
            try response.render("games-page", with: ActivitiesPageViewModel(base: base,
                                                                            type: .nearMe,
                                                                            activities: [],
                                                                            page: 0,
                                                                            hasNextPage: false))
            return next()
        }
        let pageSize = 8
        let activities = try persistence.activitiesNear(user: user, startingFrom: page * pageSize, limitedTo: pageSize)
        let remaining = try persistence.numberOfActivities(notHostedBy: user) - (page + 1) * pageSize
        try response.render("games-page", with: ActivitiesPageViewModel(base: base,
                                                                        type: .nearMe,
                                                                        activities: activities,
                                                                        page: page,
                                                                        hasNextPage: remaining > 0))
        next()
    }
}
