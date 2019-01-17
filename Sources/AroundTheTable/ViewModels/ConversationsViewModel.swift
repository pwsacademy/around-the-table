/**
 View model for **user-conversations.stencil**.
 */
struct ConversationsViewModel: Codable {
    
    let base: BaseViewModel
    
    struct ConversationViewModel: Codable {
        
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
        let latestMessage: String
        let hasUnreadMessages: Bool
        
        init(_ conversation: Conversation, for user: User) throws {
            if user == conversation.sender {
                other = try UserViewModel(conversation.recipient)
                hasUnreadMessages = conversation.messages.contains { $0.direction == .incoming && !$0.isRead }
            } else {
                other = try UserViewModel(conversation.sender)
                hasUnreadMessages = conversation.messages.contains { $0.direction == .outgoing && !$0.isRead }
            }
            guard !conversation.messages.isEmpty else {
                throw log(ServerError.invalidState)
            }
            latestMessage = conversation.messages.last!.text
        }
    }

    let conversations: [ConversationViewModel]
    
    init(base: BaseViewModel, conversations: [Conversation], for user: User) throws {
        self.base = base
        self.conversations = try conversations.map { try ConversationViewModel($0, for: user) }
    }
}
