/**
 View model for **user-conversations.stencil**.
 */
struct ConversationsViewModel: Codable {
    
    let base: BaseViewModel
    
    struct ConversationViewModel: Codable {
        
        let activity: Int
        let title: String
        let picture: String
        let userIsSender: Bool
        
        struct UserViewModel: Codable {
            
            let id: Int
            let name: String
            let picture: String
            
            init(_ user: User) throws {
                guard let id = user.id else {
                    throw log(ServerError.unpersistedEntity)
                }
                self.id = id
                self.name = user.name
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
            let isRead: Bool
            
            init(_ message: Conversation.Message) {
                self.direction = message.direction.rawValue
                self.longDate = message.timestamp.formatted(format: "EEEE d MMMM")
                self.shortDate = message.timestamp.formatted(format: "E d MMMM") // abbreviated weekday
                self.time = message.timestamp.formatted(timeStyle: .short)
                self.text = message.text
                self.isRead = message.isRead
            }
        }
        
        let messages: [MessageViewModel]
        
        init(_ conversation: Conversation, for user: User) throws {
            guard let id = conversation.topic.id else {
                throw log(ServerError.unpersistedEntity)
            }
            activity = id
            title = conversation.topic.name
            picture = conversation.topic.picture?.absoluteString ?? Settings.defaultGamePicture
            if user == conversation.sender {
                userIsSender = true
                other = try UserViewModel(conversation.recipient)
            } else if user == conversation.recipient {
                userIsSender = false
                other = try UserViewModel(conversation.sender)
            } else {
                throw log(ServerError.invalidState)
            }
            messages = conversation.messages.map(MessageViewModel.init)
        }
    }

    let conversations: [ConversationViewModel]
    
    init(base: BaseViewModel, conversations: [Conversation], for user: User) throws {
        self.base = base
        self.conversations = try conversations.map { try ConversationViewModel($0, for: user) }
    }
}
