import Credentials
import Foundation
import Kitura
import LoggerAPI

extension Routes {
    
    /**
     Registers the web/activity routes on the given router.
     */
    func configureWebActivityRoutes(using router: Router, credentials: Credentials) {
        
        // View an activity.
        router.get(":id", handler: activity)
        
        // Cancel an activity.
        router.post(":id", middleware: credentials)
        router.post(":id", handler: cancelActivity)
        
        // Edit an activity.
        router.all(":id/edit", middleware: credentials)
        router.get(":id/edit/players", handler: showEditActivityPlayerCount)
        router.post(":id/edit/players", handler: editActivityPlayerCount)
        router.get(":id/edit/datetime", handler: showEditActivityDateTime)
        router.post(":id/edit/datetime", handler: editActivityDateTime)
        router.get(":id/edit/deadline", handler: showEditActivityDeadline)
        router.post(":id/edit/deadline", handler: editActivityDeadline)
        router.get(":id/edit/address", handler: showEditActivityAddress)
        router.post(":id/edit/address", handler: editActivityAddress)
        router.get(":id/edit/info", handler: showEditActivityInfo)
        router.post(":id/edit/info", handler: editActivityInfo)
        
        // Add and edit registrations.
        router.post(":id/registrations", middleware: credentials)
        router.post(":id/registrations", handler: submitRegistration)
        router.post(":id/registrations/:player", handler: editRegistration)
    }
    
    /**
     Shows the activity's page.
     
     This has different versions:
     - A version for the host.
     - A version for players and visitors.
     - A version used when an activity is over or cancelled.
     */
    private func activity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let user = try authenticatedUser(for: request)
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id,
                                                      measuredFrom: user?.location?.coordinates ?? .default) else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        let hosts: [User]
        if let user = user {
            hosts = try persistence.hostsJoined(by: user)
        } else {
            hosts = []
        }
        let viewModel = try ActivityViewModel(base: base, activity: activity, user: user, hostsUserHasJoined: hosts)
        if activity.isCancelled || activity.date < Date() {
            try response.render("activity-closed", with: viewModel)
        } else if user == activity.host {
            try response.render("activity-host", with: viewModel)
        } else {
            try response.render("activity-player", with: viewModel)
        }
        next()
    }
    
    /**
     Cancels an activity.
     */
    private func cancelActivity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              !activity.isCancelled,
              // Past activities cannot be cancelled.
              activity.date > Date(),
              // Only the host can cancel an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        activity.isCancelled = true
        try persistence.update(activity)
        // Inform the players that the activity is cancelled.
        for player in activity.players {
            try notificationService.notify(player, thatHostCancelled: activity)
        }
        try response.redirect("/web/user/activities")
    }
    
    /**
     Shows the page to edit an activity's player count.
     */
    private func showEditActivityPlayerCount(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        try response.render("edit-activity-playercount", with: EditActivityPlayerCountViewModel(base: base, activity: activity))
        next()
    }
    
    /**
     Edit an activity's player count.
     */
    private func editActivityPlayerCount(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: EditActivityPlayerCountForm.self),
              form.isValid else {
            response.status(.badRequest)
            return next()
        }
        activity.playerCount = form.minPlayerCount...form.playerCount
        activity.prereservedSeats = form.prereservedSeats
        try persistence.update(activity)
        try response.redirect("/web/activity/\(id)")
    }
    
    /**
     Shows the page to edit an activity's date and time.
     */
    private func showEditActivityDateTime(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        try response.render("edit-activity-datetime", with: EditActivityDateTimeViewModel(base: base, activity: activity))
        next()
    }
    
    /**
     Edit an activity's date and time.
     */
    private func editActivityDateTime(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: EditActivityDateTimeForm.self),
              let date = form.date else {
            response.status(.badRequest)
            return next()
        }
        // Not only adjust the date, also adjust the deadline accordingly.
        let deadlineInterval = date.timeIntervalSince(activity.date)
        activity.date = date
        activity.deadline.addTimeInterval(deadlineInterval)
        // Inform the players that the activity's date or time has changed.
        try persistence.update(activity)
        for player in activity.players {
            try notificationService.notify(player, thatHostChangedDateFor: activity)
        }
        try response.redirect("/web/activity/\(id)")
    }
    
    /**
     Shows the page to edit an activity's deadline.
     */
    private func showEditActivityDeadline(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        try response.render("edit-activity-deadline", with: EditActivityDeadlineViewModel(base: base, activity: activity))
        next()
    }
    
    /**
     Edit an activity's deadline.
     */
    private func editActivityDeadline(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: EditActivityDeadlineForm.self),
              form.isValid else {
            response.status(.badRequest)
            return next()
        }
        switch form.deadlineType {
        case "one hour":
            activity.deadline = Settings.calendar.date(byAdding: .hour, value: -1, to: activity.date)!
        case "one day":
            activity.deadline = Settings.calendar.date(byAdding: .day, value: -1, to: activity.date)!
        case "two days":
            activity.deadline = Settings.calendar.date(byAdding: .day, value: -2, to: activity.date)!
        case "one week":
            activity.deadline = Settings.calendar.date(byAdding: .weekOfYear, value: -1, to: activity.date)!
        default:
            throw log(ServerError.invalidState) // This should be prevented by form.isValid.
        }
        try persistence.update(activity)
        try response.redirect("/web/activity/\(id)")
    }
    
    /**
     Shows the page to edit an activity's address.
     */
    private func showEditActivityAddress(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        try response.render("edit-activity-address", with: EditActivityAddressViewModel(base: base, activity: activity))
        next()
    }
    
    /**
     Edit an activity's address.
     */
    private func editActivityAddress(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: EditActivityAddressForm.self),
              form.isValid else {
            response.status(.badRequest)
            return next()
        }
        activity.location = form.location
        try persistence.update(activity)
        // Inform the players that the activity's address has changed.
        for player in activity.players {
            try notificationService.notify(player, thatHostChangedAddressFor: activity)
        }
        try response.redirect("/web/activity/\(id)")
    }
    
    /**
     Shows the page to edit an activity's info.
     */
    private func showEditActivityInfo(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        let base = try baseViewModel(for: request)
        try response.render("edit-activity-info", with: EditActivityInfoViewModel(base: base, activity: activity))
        next()
    }
    
    /**
     Edit an activity's info.
     */
    private func editActivityInfo(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // Past or cancelled activities cannot be editing.
              activity.date > Date(),
              !activity.isCancelled,
              // Only the host can edit an activity.
              activity.host == user else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: EditActivityInfoForm.self) else {
            response.status(.badRequest)
            return next()
        }
        activity.info = form.info
        try persistence.update(activity)
        try response.redirect("/web/activity/\(id)")
    }
    
    /**
     Submit a registration.
     */
    private func submitRegistration(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // You can't register for past or cancelled activities.
              activity.date > Date(),
              !activity.isCancelled,
              // You can't register more than 30 days in advance.
              activity.date.subtracting30Days < Date(),
              // A host can't register for his own activities.
              user != activity.host else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: RegistrationFrom.self),
              form.isValid else {
            response.status(.badRequest)
            return next()
        }
        var registration = Activity.Registration(player: user, seats: form.seats)
        // Automatically approve the registration if it's the player's first registration with this host in the 30-day window
        // and there are enough available seats to approve it.
        let autoApprove = try !persistence.hostsJoined(by: user).contains(activity.host) && activity.availableSeats >= form.seats
        if autoApprove {
            registration.isApproved = true
        }
        activity.registrations.append(registration)
        try persistence.update(activity)
        if autoApprove {
            // Inform the host that a player has joined.
            try notificationService.notify(activity.host, that: user, joined: activity)
            // Inform the player that his registration was automatically approved.
            try notificationService.notify(user, ofAutomaticApprovalFor: activity)
        } else {
            // Inform the host of the new registration.
            try notificationService.notify(activity.host, that: user, sentRegistrationFor: activity)
        }
        try response.redirect("/web/activity/\(id)")
    }
    
    /**
     Approve or cancel a registration.
     */
    private func editRegistration(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let idString = request.parameters["id"],
              let id = Int(idString),
              let activity = try persistence.activity(withID: id, measuredFrom: .default),
              // You can't edit registrations for past or cancelled activities.
              activity.date > Date(),
              !activity.isCancelled else {
            response.status(.badRequest)
            return next()
        }
        // Look up the player whose registration is being edited.
        guard let playerIDString = request.parameters["player"],
              let playerID = Int(playerIDString),
              let player = try persistence.user(withID: playerID) else {
            response.status(.badRequest)
            return next()
        }
        // This player must already have a registration.
        // As a player may register, cancel and then register again, we edit the player's last (most recent) registration.
        guard let index = activity.registrations.lastIndex(where: { $0.player == player }) else {
            response.status(.badRequest)
            return next()
        }
        guard let form = try? request.read(as: EditRegistrationForm.self) else {
            response.status(.badRequest)
            return next()
        }
        // Either the registration is approved by the host...
        if let approved = form.approved, approved, user == activity.host {
            activity.registrations[index].isApproved = true
            try persistence.update(activity)
            // Inform the player that his registration has been approved.
            try notificationService.notify(player, thatHostApprovedRegistrationFor: activity)
        // ...or it is cancelled by the player...
        } else if let cancelled = form.cancelled, cancelled, user == player {
            activity.registrations[index].isCancelled = true
            try persistence.update(activity)
            // Inform the host that a registration has been cancelled.
            try notificationService.notify(activity.host, that: player, cancelledRegistrationFor: activity)
        // ...or it is cancelled by the host.
        } else if let cancelled = form.cancelled, cancelled, user == activity.host {
            activity.registrations[index].isCancelled = true
            try persistence.update(activity)
            // Inform the player that his registration has been cancelled.
            try notificationService.notify(player, thatHostCancelledRegistrationFor: activity)
        }
        try response.redirect("/web/activity/\(id)")
    }
}
