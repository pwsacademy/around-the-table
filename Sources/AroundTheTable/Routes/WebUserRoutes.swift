import Credentials
import Kitura
import KituraSession

extension Routes {
    
    /**
     Registers the web/user routes on the given router.
     */
    func configureWebUserRoutes(using router: Router, credentials: Credentials) {
        router.all(middleware: credentials)
        router.get("activities", handler: activities)
        router.get("conversations", handler: conversations)
        router.get("conversations/:other", handler: conversation)
        router.post("conversations", handler: sendMessage)
        router.get("settings", handler: settings)
        router.post("settings", handler: editSettings)
    }
    
    /**
     Shows the activities the user is hosting or the user has joined.
     */
    private func activities(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        let view: String
        if let viewParameter = request.queryParameters["view"] {
            // If a view is specified, it is stored in the user's session.
            view = viewParameter
            session["preferredUserActivitiesView"] = viewParameter
        } else {
            // If no view is specified, either the user's stored (last) view is used, or the default, list.
            view = session["preferredUserActivitiesView"] as? String ?? "list"
        }
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
     Shows an overview of the user's conversations.
     */
    private func conversations(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        let conversations = try persistence.conversations(for: user)
        let base = try baseViewModel(for: request)
        try response.render("user-conversations", with: try ConversationsViewModel(base: base,
                                                                                   conversations: conversations,
                                                                                   for: user))
        next()
    }
    
    /**
     Shows a conversation.
     */
    private func conversation(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let otherIDString = request.parameters["other"],
              let otherID = Int(otherIDString),
              let other = try persistence.user(withID: otherID),
              let conversation = try persistence.conversation(between: user, other) else {
            response.status(.badRequest)
            return next()
        }
        // Mark all messages for the current user in this conversation as read.
        for i in 0..<conversation.messages.count {
            if user == conversation.sender && conversation.messages[i].direction == .incoming
            || user == conversation.recipient && conversation.messages[i].direction == .outgoing {
                conversation.messages[i].isRead = true
            }
        }
        try persistence.update(conversation)
        let base = try baseViewModel(for: request)
        try response.render("user-conversation", with: try ConversationViewModel(base: base,
                                                                                 conversation: conversation,
                                                                                 for: user))
        next()
    }
    
    /**
     Adds a message to a conversation.
     Creates a new conversation if one doesn't exist.
     */
    private func sendMessage(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let form = try? request.read(as: MessageForm.self),
              let sender = try persistence.user(withID: form.sender),
              sender == user,
              let recipient = try persistence.user(withID: form.recipient) else {
            response.status(.badRequest)
            return next()
        }
        let message: String
        if let id = form.topic, let topic = try persistence.activity(withID: id, measuredFrom: .default) {
            // If the user sent a message via the contact form on an activiy page,
            // add a prefix to the message to provide some context.
            message = Strings.messagePrefix(for: topic) + form.text
        } else {
            message = form.text
        }
        if let conversation = try persistence.conversation(between: sender, recipient) {
            let direction = sender == conversation.sender ? Conversation.Message.Direction.outgoing : .incoming
            conversation.messages.append(Conversation.Message(direction: direction, text: message))
            try persistence.update(conversation)
        } else {
            let conversation = Conversation(sender: sender, recipient: recipient)
            conversation.messages.append(Conversation.Message(direction: .outgoing, text: message))
            try persistence.add(conversation)
        }
        try response.redirect("/web/user/conversations/\(form.recipient)")
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
