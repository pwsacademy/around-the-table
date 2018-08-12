import Credentials
import Kitura

extension Routes {
    
    /**
     Registers the web/user routes on the given router.
     */
    func configureWebUserRoutes(using router: Router, credentials: Credentials) {
        router.all(middleware: credentials)
        router.get("activities", handler: activities)
        router.get("messages", handler: conversations)
        router.get("settings", handler: settings)
        router.post("settings", handler: editSettings)
    }
    
    /**
     Shows the activities the user is hosting or the user has joined.
     */
    private func activities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        let view = request.queryParameters["view"] ?? "list"
        guard ["grid", "list"].contains(view) else {
            response.status(.badRequest)
            return next()
        }
        let hosted = try persistence.activities(hostedBy: user)
        let joined = try persistence.activities(joinedBy: user)
        let base = try baseViewModel(for: request)
        try response.render("user-activities-\(view)", with: UserActivitiesViewModel(base: base,
                                                                                     hosted: hosted,
                                                                                     joined: joined))
        next()
    }
    
    /**
     Shows the user's active conversations.
     */
    private func conversations(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        let conversations = try persistence.conversations(for: user)
        let base = try baseViewModel(for: request)
        try response.render("user-conversations", with: try ConversationsViewModel(base: base, conversations: conversations, for: user))
        // Mark all messages for the current user as read.
        for conversation in conversations {
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
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        let base = try baseViewModel(for: request)
        let facebookID = try persistence.facebookID(for: user)
        try response.render("user-settings", with: UserSettingsViewModel(base: base,
                                                                         saved: false,
                                                                         userHasFacebookCredential: facebookID != nil))
        next()
    }
    
    /**
     Processes the form submitted to change the user's settings.
     */
    private func editSettings(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let form = try? request.read(as: EditSettingsForm.self) else {
            response.status(.badRequest)
            return next()
        }
        user.location = form.location
        try persistence.update(user)
        let base = try baseViewModel(for: request)
        let facebookID = try persistence.facebookID(for: user)
        try response.render("user-settings", with: UserSettingsViewModel(base: base,
                                                                         saved: true,
                                                                         userHasFacebookCredential: facebookID != nil))
        next()
    }
}
