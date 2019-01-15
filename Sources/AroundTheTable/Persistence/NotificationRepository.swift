import Foundation
import LoggerAPI
import MongoKitten

/**
 Persistence methods related to notifications.
 */
extension Persistence {
    
    /**
     Adds a new notification to the database.
     
     The notification's timestamp may be adjusted if there's a primary key conflict.
     */
    func add(_ notification: Notification) throws {
        while try notifications.findOne(["_id": notification.timestamp]) != nil {
            Log.warning("Adjusted a notification timestamp to resolve a conflict.")
            notification.timestamp = Date()
        }
        try notifications.insert(notification.document)
    }
    
    /**
     Returns the number of unread notifications for the given user.
     */
    func unreadNotificationCount(for recipient: User) throws -> Int {
        guard let id = recipient.id else {
            throw log(ServerError.unpersistedEntity)
        }
        return try notifications.count(["recipient": id, "isRead": false])
    }
    
    /**
     Returns all notifications (read or unread) for the given user.
     */
    func notifications(for recipient: User) throws -> [Notification] {
        guard let id = recipient.id else {
            throw log(ServerError.unpersistedEntity)
        }
        let results = try notifications.aggregate([
            .match(["recipient": id] as Query),
            .lookup(from: users, localField: "recipient", foreignField: "_id", as: "recipient"),
            .sort(["_id": .descending]),
            .unwind("$recipient")
        ])
        return try results.compactMap(Notification.init)
    }
    
    /**
     Marks all notifications for the given user, up to a given timestamp, as read.
     
     The timestamp is used to avoid accidentally marking a new notification as read.
     This could happen if a notification arrives right after the user fetches his notifications,
     and we then mark *all* his notifications (including the new, unread one) as read.
     */
    func markNotificationsAsRead(for recipient: User, upTo timestamp: Date) throws {
        guard let id = recipient.id else {
            throw log(ServerError.unpersistedEntity)
        }
        try notifications.update(["_id": ["$lte": timestamp], "recipient": id],
                                 to: ["$set": ["isRead": true]], multiple: true)
    }
    
    /**
     Removes all read notifications for the given user from the database.
     */
    func removeReadNotifications(for recipient: User) throws {
        guard let id = recipient.id else {
            throw log(ServerError.unpersistedEntity)
        }
        try notifications.remove(["recipient": id, "isRead": true])
    }
}
