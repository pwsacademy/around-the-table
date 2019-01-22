import HTMLEntities

/**
 View model for **user-notifications.stencil**.
 */
struct NotificationsViewModel: Codable {
    
    let base: BaseViewModel
    
    struct NotificationViewModel: Codable {
        
        let longDate: String
        let shortDate: String
        let time: String
        let message: String
        let link: String
        let isRead: Bool
        
        init(_ notification: Notification) {
            longDate = notification.timestamp.formatted(format: "EEEE d MMMM")
            shortDate = notification.timestamp.formatted(format: "E d MMMM") // abbreviated weekday
            time = notification.timestamp.formatted(timeStyle: .short)
            message = notification.message.htmlEscape()
            link = notification.link
            isRead = notification.isRead
        }
    }
    
    let notifications: [NotificationViewModel]
    
    init(base: BaseViewModel, notifications: [Notification]) throws {
        self.base = base
        self.notifications = notifications.map(NotificationViewModel.init)
    }
}
