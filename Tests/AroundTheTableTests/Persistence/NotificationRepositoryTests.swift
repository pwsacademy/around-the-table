import XCTest
@testable import AroundTheTable

/**
 Run these tests against the **aroundthetable-test** database.
 Import it from **Tests/AroundTheTable/Fixtures/dump**.
 */
class NotificationRepositoryTests: XCTestCase {
    
    static var allTests: [(String, (NotificationRepositoryTests) -> () throws -> Void)] {
        return [
            ("testAddNotification", testAddNotification),
            ("testAddNotificationResolvesConflicts", testAddNotificationResolvesConflicts),
            ("testUnreadNotificationCount", testUnreadNotificationCount),
            ("testNotificationsForRecipient", testNotificationsForRecipient),
            ("testMarkNotificationsAsRead", testMarkNotificationsAsRead),
            ("testRemoveReadNotifications", testRemoveReadNotifications)
        ]
    }
    
    private let persistence = try! Persistence()
    private var recipient = User(id: 1, name: "Recipient")
    
    func testAddNotification() throws {
        let notification = Notification(recipient: recipient, message: "Test", link: "activity/1")
        try persistence.add(notification)
        XCTAssertNotNil(try persistence.notifications.findOne(["_id": notification.timestamp]))
        // Clean-up
        try persistence.notifications.remove(["_id": notification.timestamp])
    }
    
    func testAddNotificationResolvesConflicts() throws {
        let timestamp = Date()
        let first = Notification(timestamp: timestamp, recipient: recipient, message: "First", link: "activity/1")
        let second = Notification(timestamp: timestamp, recipient: recipient, message: "Second", link: "activity/1")
        try persistence.add(first)
        try persistence.add(second)
        XCTAssert(first.timestamp == timestamp)
        XCTAssert(second.timestamp != timestamp)
        // Clean-up
        try persistence.notifications.remove(["_id": ["$in": [first.timestamp, second.timestamp]]])
    }
    
    func testUnreadNotificationCount() throws {
        XCTAssert(try persistence.unreadNotificationCount(for: recipient) == 2)
    }

    func testNotificationsForRecipient() throws {
        let results = try persistence.notifications(for: recipient)
        XCTAssert(results.count == 3)
    }
    
    func testMarkNotificationsAsRead() throws {
        guard let unreadNotification = try persistence.notifications.findOne(["message": "Unread notification"]),
              let timestamp = Date(unreadNotification["_id"]) else {
            return XCTFail()
        }
        try persistence.markNotificationsAsRead(for: recipient, upTo: timestamp)
        // The notification after the timestamp should not be marked as read.
        XCTAssert(try persistence.unreadNotificationCount(for: recipient) == 1)
        // Clean-up
        try persistence.notifications.update(["message": "Unread notification"],
                                             to: ["$set": ["isRead": false]])
    }
    
    func testRemoveReadNotifications() throws {
        guard let readNotification = try persistence.notifications.findOne(["message": "Read notification"]) else {
            return XCTFail()
        }
        try persistence.removeReadNotifications(for: recipient)
        XCTAssert(try persistence.notifications(for: recipient).count == 2)
        // Clean-up
        try persistence.notifications.insert(readNotification)
    }
}
