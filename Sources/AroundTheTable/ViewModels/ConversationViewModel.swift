import HTMLEntities

/**
 View model for **user-conversation.stencil**.
 */
struct ConversationViewModel: Codable {
    
    let base: BaseViewModel
    
    struct UserViewModel: Codable {
        
        let id: Int
        let name: String
        let picture: String
        
        init(_ user: User) throws {
            guard let id = user.id else {
                throw log(ServerError.unpersistedEntity)
            }
            self.id = id
            self.name = user.name.htmlEscape()
            self.picture = user.picture?.absoluteString ?? Settings.defaultProfilePicture
        }
    }
    
    let other: UserViewModel
    
    struct MessageViewModel: Codable {
        
        let direction: String
        let longDate: String
        let shortDate: String
        let time: String
        let text: String
        
        init(_ message: Conversation.Message, userIsSender: Bool) {
            // Convert the messages' direction to the user's point of view.
            switch (message.direction, userIsSender) {
            case (.incoming, true), (.outgoing, false):
                direction = "incoming"
            case (.incoming, false), (.outgoing, true):
                direction = "outgoing"
            }
            self.longDate = message.timestamp.formatted(format: "EEEE d MMMM")
            self.shortDate = message.timestamp.formatted(format: "E d MMMM") // abbreviated weekday
            self.time = message.timestamp.formatted(timeStyle: .short)
            self.text = message.text.htmlEscape()
        }
    }
    
    let messages: [MessageViewModel]
    
    init(base: BaseViewModel, conversation: Conversation, for user: User) throws {
        self.base = base
        if user == conversation.sender {
            other = try UserViewModel(conversation.recipient)
            messages = conversation.messages.map { MessageViewModel($0, userIsSender: true) }
        } else {
            other = try UserViewModel(conversation.sender)
            messages = conversation.messages.map { MessageViewModel($0, userIsSender: false) }
        }
    }
}
