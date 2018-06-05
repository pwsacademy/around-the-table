import Credentials
import Kitura

extension Routes {
    
    /**
     Registers the web routes on the given router.
     */
    func configureWeb(using router: Router, credentials: Credentials) {
        
        // Root pages.
        router.get("home", handler: home)
        router.get("faq", handler: faq)
        
        // Overview of activities.
        router.get("games", handler: activities)
        router.get("newest-games", handler: newestActivities)
        router.get("upcoming-games", handler: upcomingActivities)
        router.get("games-near-me", handler: activitiesNearMe)
        
        let authentication = AuthenticationMiddleware(persistence: persistence)
        
        // Create an activity.
        router.get("host", handler: host)
        router.get("host-game-select", handler: selectGame)
        router.all("host-game", middleware: [credentials, authentication])
        router.get("host-game", handler: createActivity)
        router.post("host-game", handler: submitActivity)
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
    
    /**
     Shows the options for hosting an activity.
     */
    private func host(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("host", with: HostViewModel(base: base, query: "", error: false))
        next()
    }
    
    /**
     When searching for a game to host, the user is presented with this selection page.
     */
    private func selectGame(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) -> Void {
        guard let query = request.queryParameters["query"], query.count > 0 else {
            response.status(.badRequest)
            return next()
        }
        persistence.games(forQuery: query, exactMatchesOnly: request.queryParameters["exact"] == "on") {
            ids in
            do {
                guard ids.count > 0 else {
                    let base = try self.baseViewModel(for: request)
                    try response.render("host", with: HostViewModel(base: base, query: query, error: true))
                    return next()
                }
                try self.persistence.games(forIDs: ids) {
                    games in
                    do {
                        let base = try self.baseViewModel(for: request)
                        try response.render("game-selection", with: GameSelectionViewModel(
                            base: base,
                            results: games.sorted { $0.yearPublished > $1.yearPublished }
                        ))
                    } catch {
                        response.error = error
                    }
                    next()
                }
            } catch {
                response.error = error
                next()
            }
        }
    }
    
    /**
     After selecting a game to host, the user is presented with this form to create an activity.
     */
    private func createActivity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard try persistence.user(withID: userID) != nil else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        guard let idString = request.queryParameters["id"], let id = Int(idString) else {
            response.status(.badRequest)
            return next()
        }
        try persistence.game(forID: id) {
            game in
            guard let game = game else {
                response.status(.badRequest)
                return next()
            }
            do {
                self.persistence.checkMediumPicture(for: game)
                let base = try self.baseViewModel(for: request)
                try response.render("host-game", with: HostActivityViewModel(base: base, game: game))
            } catch {
                response.error = error
            }
            next()
        }
    }
    
    /**
     Processes the form submitted to host an activity.
     */
    private func submitActivity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try persistence.user(withID: userID) else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        guard let form = try? request.read(as: ActivityForm.self), form.isValid else {
            response.status(.badRequest)
            return next()
        }
        try persistence.game(forID: form.game) {
            game in
            guard let game = game else {
                response.status(.badRequest)
                return next()
            }
            let activity = Activity(host: user,
                                    name: form.name,
                                    game: game,
                                    playerCount: form.minPlayerCount...form.playerCount,
                                    prereservedSeats: form.prereservedSeats,
                                    date: form.date!,
                                    deadline: form.deadline!,
                                    location: form.location,
                                    info: form.info)
            do {
                try self.persistence.add(activity)
                guard let id = activity.id else {
                    response.error = ServerError.invalidState
                    return next()
                }
                try response.redirect("/web/game/\(id.hexString)")
            } catch {
                response.error = error
                next()
            }
        }
    }
}
