import BSON
import Credentials
import Foundation
import Kitura
import LoggerAPI

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
        
        // View and edit activities.
        router.get("game/:id", handler: activity)
        router.get("game/:id/edit", middleware: [credentials, authentication])
        router.get("game/:id/edit", handler: editActivity)
        router.post("game/:id/edit", handler: submitEditActivity)
        
        // Submit and edit registrations.
        router.post("game/:id/registrations", middleware: [credentials, authentication])
        router.post("game/:id/registrations", handler: submitRegistration)
        router.post("game/:id/registrations/:player", middleware: [credentials, authentication])
        router.post("game/:id/registrations/:player", handler: editRegistration)
        
        // Pages from the user's personal menu.
        router.all("my-games", middleware: [credentials, authentication])
        router.get("my-games", handler: myActivities)
        router.get("messages", middleware: [credentials, authentication])
        router.get("messages", handler: conversations)
        router.all("settings", middleware: [credentials, authentication])
        router.get("settings", handler: settings)
        router.post("settings", handler: editSettings)
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
                self.storeImages(for: activity)
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
    
    /**
     Stores an activity's picture and thumbnail in cloud object storage and updates the links.
     Does nothing if cloud object storage is not configured.
     */
    private func storeImages(for activity: Activity) {
        guard let id = activity.id?.hexString,
              let picture = activity.picture,
              let thumbnail = activity.thumbnail,
              CloudObjectStorage.isConfigured else {
            return
        }
        
        func getExtension(for url: URL) -> String? {
            guard let file = url.absoluteString.components(separatedBy: "/").last,
                  let period = file.index(of: ".") else {
                return nil
            }
            return String(file[period...])
        }
        
        guard let pictureExtension = getExtension(for: picture),
              let thumbnailExtension = getExtension(for: thumbnail) else {
            Log.warning("COS warning: failed to get extensions for \(picture) and/or \(thumbnail).")
            return
        }
        let pictureObject = "activity/\(id)/picture\(pictureExtension)"
        let thumbnailObject = "activity/\(id)/thumbnail\(thumbnailExtension)"
        let cos = CloudObjectStorage()
        cos.storeImage(at: picture, as: pictureObject) {
            cos.storeImage(at: thumbnail, as: thumbnailObject) {
                activity.picture = URL(string: "\(Settings.cloudObjectStorage.bucketURL!)/\(pictureObject)")
                activity.thumbnail = URL(string: "\(Settings.cloudObjectStorage.bucketURL!)/\(thumbnailObject)")
                do {
                    try self.persistence.update(activity)
                } catch {
                    Log.warning("COS warning: failed to persist activity \(id) after update.")
                }
            }
        }
    }
    
    /**
     Gives detailed information about an activity, including its approved and pending registrations.
     */
    private func activity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let user: User?
        if let userID = request.userProfile?.id {
            guard let existingUser = try persistence.user(withID: userID) else {
                throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
            }
            user = existingUser
        } else {
            user = nil
        }
        guard let id = request.parameters["id"],
              let activity = try persistence.activity(with: ObjectId(id),
                                                      measuredFrom: user?.location?.coordinates ?? .default) else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        try response.render("game", with: ActivityViewModel(base: base,
                                                            user: user,
                                                            activity: activity))
        next()
    }
    
    /**
     Editable view of an activity.
     */
    private func editActivity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try persistence.user(withID: userID) else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        guard let id = request.parameters["id"],
              let activity = try persistence.activity(with: ObjectId(id), measuredFrom: .default),
              activity.date.compare(Date()) == .orderedDescending,
              activity.host == user,
              let type = request.queryParameters["type"],
              ["players", "datetime", "deadline", "address", "info"].contains(type) else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        try response.render("host-game", with: EditActivityViewModel(base: base, activity: activity, type: type))
        next()
    }
    
    /**
     Processes the form submitted to edit or cancel an activity.
     */
    private func submitEditActivity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try persistence.user(withID: userID) else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        guard let id = request.parameters["id"],
              let activity = try persistence.activity(with: ObjectId(id), measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date.compare(Date()) == .orderedDescending,
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: EditActivityForm.self) else {
            response.status(.badRequest)
            return next()
        }
        switch form.result {
        case .players(let count, let min, let prereserved):
            activity.playerCount = min...count
            activity.prereservedSeats = prereserved
            try persistence.update(activity)
            try response.redirect("/web/game/\(id)")
        case .date(let date):
            // Not only adjust the date, also adjust the deadline accordingly.
            let deadlineInterval = date.timeIntervalSince(activity.date)
            activity.date = date
            activity.deadline.addTimeInterval(deadlineInterval)
            try persistence.update(activity)
            for player in activity.players {
                if let conversation = try persistence.conversation(between: user, player, regarding: activity) {
                    conversation.hostChangedDate()
                    try persistence.update(conversation)
                } else {
                    let conversation = Conversation(topic: activity, sender: user, recipient: player)
                    conversation.hostChangedDate()
                    try persistence.add(conversation)
                    Log.warning("Created a conversation that should already exist: \(String(describing: conversation.id)).")
                }
            }
            try response.redirect("/web/game/\(id)")
        case .deadline(let type):
            let calendar = Calendar(identifier: .gregorian)
            switch type {
            case "one hour":
                activity.deadline = calendar.date(byAdding: .hour, value: -1, to: activity.date)!
            case "one day":
                activity.deadline = calendar.date(byAdding: .day, value: -1, to: activity.date)!
            case "two days":
                activity.deadline = calendar.date(byAdding: .day, value: -2, to: activity.date)!
            case "one week":
                activity.deadline = calendar.date(byAdding: .weekOfYear, value: -1, to: activity.date)!
            default:
                response.status(.badRequest)
                return next()
            }
            try persistence.update(activity)
            try response.redirect("/web/game/\(id)")
        case .address(let location):
            activity.location = location
            try persistence.update(activity)
            for player in activity.players {
                if let conversation = try persistence.conversation(between: user, player, regarding: activity) {
                    conversation.hostChangedAddress()
                    try persistence.update(conversation)
                } else {
                    let conversation = Conversation(topic: activity, sender: user, recipient: player)
                    conversation.hostChangedAddress()
                    try persistence.add(conversation)
                    Log.warning("Created a conversation that should already exist: \(String(describing: conversation.id)).")
                }
            }
            try response.redirect("/web/game/\(id)")
        case .info(let info):
            activity.info = info
            try persistence.update(activity)
            try response.redirect("/web/game/\(id)")
        case .cancel:
            activity.isCancelled = true
            try persistence.update(activity)
            for player in activity.players {
                if let conversation = try persistence.conversation(between: user, player, regarding: activity) {
                    conversation.hostCancelledActivity()
                    try persistence.update(conversation)
                } else {
                    let conversation = Conversation(topic: activity, sender: user, recipient: player)
                    conversation.hostCancelledActivity()
                    try persistence.add(conversation)
                    Log.warning("Created a conversation that should already exist: \(String(describing: conversation.id)).")
                }
            }
            try response.redirect("/web/my-games")
        case .invalid:
            response.status(.badRequest)
            return next()
        }
    }
    
    /**
     Submit a registration.
     */
    private func submitRegistration(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try persistence.user(withID: userID) else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        guard let id = request.parameters["id"],
              let activity = try persistence.activity(with: ObjectId(id), measuredFrom: .default),
              // You can't register for past or cancelled activities.
              activity.date.compare(Date()) == .orderedDescending,
              !activity.isCancelled else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: ActivityRegistrationFrom.self),
              form.seats >= 1 else {
            response.status(.badRequest)
            return next()
        }
        activity.registrations.append(Activity.Registration(player: user, seats: form.seats))
        try persistence.update(activity)
        if let conversation = try persistence.conversation(between: user, activity.host, regarding: activity) {
            conversation.playerSentRegistration()
            try persistence.update(conversation)
        } else {
            let conversation = Conversation(topic: activity, sender: user, recipient: activity.host)
            conversation.playerSentRegistration()
            try persistence.add(conversation)
        }
        try response.redirect("/web/game/\(id)")
    }

    /**
     Approve or cancel a registration.
     */
    private func editRegistration(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try persistence.user(withID: userID) else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        guard let id = request.parameters["id"],
              let activity = try persistence.activity(with: ObjectId(id), measuredFrom: .default),
              // You can't edit registrations for past or cancelled activities.
              activity.date.compare(Date()) == .orderedDescending,
              !activity.isCancelled else {
            response.status(.badRequest)
            return next()
        }
        guard let playerID = request.parameters["player"],
              let player = try persistence.user(withID: playerID) else {
            response.status(.badRequest)
            return next()
        }
        guard let index = activity.registrations.lastIndex(where: { $0.player == player }) else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: EditActivityRegistrationForm.self) else {
            response.status(.badRequest)
            return next()
        }
        if let approved = form.approved, approved, user == activity.host {
            activity.registrations[index].isApproved = true
            try persistence.update(activity)
            if let conversation = try persistence.conversation(between: user, player, regarding: activity) {
                conversation.hostApprovedRegistration()
                try persistence.update(conversation)
            } else {
                let conversation = Conversation(topic: activity, sender: user, recipient: player)
                conversation.hostApprovedRegistration()
                try persistence.add(conversation)
                Log.warning("Created a conversation that should already exist: \(String(describing: conversation.id)).")
            }
        } else if let cancelled = form.cancelled, cancelled, user == player {
            activity.registrations[index].isCancelled = true
            try persistence.update(activity)
            if let conversation = try persistence.conversation(between: user, activity.host, regarding: activity) {
                conversation.playerCancelledRegistration()
                try persistence.update(conversation)
            } else {
                let conversation = Conversation(topic: activity, sender: user, recipient: activity.host)
                conversation.playerCancelledRegistration()
                try persistence.add(conversation)
                Log.warning("Created a conversation that should already exist: \(String(describing: conversation.id)).")
            }
        } else if let cancelled = form.cancelled, cancelled, user == activity.host {
            activity.registrations[index].isCancelled = true
            try persistence.update(activity)
            if let conversation = try persistence.conversation(between: user, player, regarding: activity) {
                conversation.hostCancelledRegistration()
                try persistence.update(conversation)
            } else {
                let conversation = Conversation(topic: activity, sender: user, recipient: player)
                conversation.hostCancelledRegistration()
                try persistence.add(conversation)
                Log.warning("Created a conversation that should already exist: \(String(describing: conversation.id)).")
            }
        }
        try response.redirect("/web/game/\(id)")
    }
    
    /**
     Shows an overview of the activities the user is hosting and the activities the user has joined.
     */
    private func myActivities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try persistence.user(withID: userID) else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        let hosted = try persistence.activities(hostedBy: user)
        let joined = try persistence.activities(joinedBy: user)
        let base = try baseViewModel(for: request)
        try response.render("my-games", with: MyActivitiesViewModel(base: base,
                                                                    hosted: hosted,
                                                                    joined: joined))
        next()
    }
    
    /**
     Shows the current user's active conversations.
     */
    private func conversations(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try persistence.user(withID: userID) else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        let conversations = try persistence.conversations(for: user)
        let base = try baseViewModel(for: request)
        try response.render("messages", with: try ConversationsViewModel(base: base, conversations: conversations, for: user))
        for conversation in conversations {
            // Mark all messages for the current user as read.
            for (index, message) in conversation.messages.enumerated() {
                if user == conversation.sender && message.direction == .incoming ||
                   user == conversation.recipient && message.direction == .outgoing {
                    conversation.messages[index].isRead = true
                }
            }
            try persistence.update(conversation)
        }
        next()
    }
    
    /**
     Shows the user's settings.
     */
    private func settings(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard try persistence.user(withID: userID) != nil else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        let base = try baseViewModel(for: request)
        try response.render("settings", with: SettingsViewModel(base: base, saved: false))
        next()
    }
    
    /**
     Processes the form submitted to change the user's settings.
     */
    private func editSettings(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let userID = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try persistence.user(withID: userID) else {
            throw log(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        guard let form = try? request.read(as: EditSettingsForm.self) else {
            response.status(.badRequest)
            return next()
        }
        user.location = form.location
        try persistence.update(user)
        let base = try baseViewModel(for: request)
        try response.render("settings", with: SettingsViewModel(base: base, saved: true))
        next()
    }
}
