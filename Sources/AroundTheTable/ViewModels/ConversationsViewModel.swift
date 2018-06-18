/**
 View model for **messages.stencil**.
 */
struct ConversationsViewModel: Codable {
    
    let base: BaseViewModel
    
    struct UserViewModel: Codable {
        
        let name: String
        let picture: String
        
        init(_ user: User) {
            self.name = user.name
            self.picture = user.picture?.absoluteString ?? Settings.defaultProfilePicture
        }
    }
    
    struct ConversationViewModel: Codable {
        
        let activity: String
        let title: String
        let picture: String
        let userIsSender: Bool
        let other: UserViewModel
        
        struct MessageViewModel: Codable {
            
            let direction: String
            let timestamp: String
            let text: String
            let isRead: Bool
            
            init(_ message: Conversation.Message) {
                self.direction = message.direction.rawValue
                self.timestamp = message.timestamp.formatted(dateStyle: .full, timeStyle: .short)
                self.text = message.text
                self.isRead = message.isRead
            }
        }
        
        let messages: [MessageViewModel]
        
        init(_ conversation: Conversation, for user: User) throws {
            guard let id = conversation.topic.id else {
                throw log(ServerError.unpersistedEntity)
            }
            activity = id.hexString
            title = conversation.topic.name
            picture = conversation.topic.game?.thumbnail?.absoluteString ?? Settings.defaultGameThumbnail
            if user == conversation.sender {
                userIsSender = true
                other = UserViewModel(conversation.recipient)
            } else if user == conversation.recipient {
                userIsSender = false
                other = UserViewModel(conversation.sender)
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
