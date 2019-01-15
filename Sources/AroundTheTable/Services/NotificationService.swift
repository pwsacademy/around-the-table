/**
 A service that sends notifications to users.
 */
public class NotificationService {
    
    /// The persistence layer.
    private let persistence: Persistence
    
    /**
     Initializes a notification service.
     */
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    /**
     Sends a notification to inform a player that his registration for an activity was automatically approved.
     */
    func notify(_ player: User, ofAutomaticApprovalFor activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.registrationWasAutoApproved(for: activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: player, message: message, link: link)
        try persistence.add(notification)
    }
    
    /**
     Sends a notification to inform a player that a host approved his registration for an activity.
     */
    func notify(_ player: User, thatHostApprovedRegistrationFor activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.hostApprovedRegistration(for: activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: player, message: message, link: link)
        try persistence.add(notification)
    }
    
    /**
     Sends a notification to inform a player that a host cancelled an activity.
     */
    func notify(_ player: User, thatHostCancelled activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.hostCancelled(activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: player, message: message, link: link)
        try persistence.add(notification)
    }
    
    /**
     Sends a notification to inform a player that a host cancelled his registration for an activity.
     */
    func notify(_ player: User, thatHostCancelledRegistrationFor activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.hostCancelledRegistration(for: activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: player, message: message, link: link)
        try persistence.add(notification)
    }
    
    /**
     Sends a notification to inform a player that a host changed the location of an activity.
     */
    func notify(_ player: User, thatHostChangedAddressFor activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.hostChangedAddress(of: activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: player, message: message, link: link)
        try persistence.add(notification)
    }
    
    /**
     Sends a notification to inform a player that a host changed the date or time of an activity.
     */
    func notify(_ player: User, thatHostChangedDateFor activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.hostChangedDate(of: activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: player, message: message, link: link)
        try persistence.add(notification)
    }
    
    /**
     Sends a notification to inform a host that a player cancelled his registration for an activity.
     */
    func notify(_ host: User, that player: User, cancelledRegistrationFor activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.player(player, cancelledRegistrationFor: activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: host, message: message, link: link)
        try persistence.add(notification)
    }
    
    /**
     Sends a notification to inform a host that a player's registration for an activity was automatically approved.
     */
    func notify(_ host: User, that player: User, joined activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.player(player, joined: activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: host, message: message, link: link)
        try persistence.add(notification)
    }
    
    /**
     Sends a notification to inform a host that a player submitted a registration for an activity.
     */
    func notify(_ host: User, that player: User, sentRegistrationFor activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let message = Strings.player(player, sentRegistrationFor: activity)
        let link = "activity/\(id)"
        let notification = Notification(recipient: host, message: message, link: link)
        try persistence.add(notification)
    }
}
