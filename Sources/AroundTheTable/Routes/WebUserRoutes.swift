import BSON
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
        router.get("messages", handler: conversations)
        router.post("messages", handler: sendMessage)
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
     Adds a message to a conversation.
     Creates a new conversation if one doesn't exist.
     */
    private func sendMessage(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let form = try? request.read(as: MessageForm.self),
              let sender = try persistence.user(withID: ObjectId(form.sender)),
              sender == user,
              let recipient = try persistence.user(withID: ObjectId(form.recipient)),
              let topic = try persistence.activity(with: ObjectId(form.topic), measuredFrom: .default) else {
            response.status(.badRequest)
            return next()
        }
        if let conversation = try persistence.conversation(between: sender, recipient, regarding: topic) {
            let direction = sender == conversation.sender ? Conversation.Message.Direction.outgoing : .incoming
            conversation.messages.append(Conversation.Message(direction: direction, text: form.text))
            try persistence.update(conversation)
        } else {
            // A message is sent from a visitor/player to an activity's host.
            guard recipient == topic.host else {
                response.status(.badRequest)
                return next()
            }
            let conversation = Conversation(topic: topic, sender: sender, recipient: recipient)
            conversation.messages.append(Conversation.Message(direction: .outgoing, text: form.text))
            try persistence.add(conversation)
        }
        try response.redirect("/web/user/messages")
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
