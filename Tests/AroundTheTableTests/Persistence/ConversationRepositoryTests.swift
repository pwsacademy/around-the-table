import BSON
import XCTest
@testable import AroundTheTable

/**
 Run these tests against the **aroundthetable-test** database.
 Import it from **Tests/AroundTheTable/Fixtures/dump**.
 */
class ConversationRepositoryTests: XCTestCase {
    
    static var allTests: [(String, (ConversationRepositoryTests) -> () throws -> Void)] {
        return [
            ("testAddConversation", testAddConversation),
            ("testAddPersistedConversation", testAddPersistedConversation),
            ("testFindConversation", testFindConversation),
            ("testFindConversationRegardingUnpersistedActivity", testFindConversationRegardingUnpersistedActivity),
            ("testConversationsForUser", testConversationsForUser),
            ("testUnreadMessageCount", testUnreadMessageCount),
            ("testUnreadMessageCountZero", testUnreadMessageCountZero),
            ("testUpdateConversation", testUpdateConversation),
            ("testUpdateUnpersistedConversation", testUpdateUnpersistedConversation)
        ]
    }
    
    let persistence = try! Persistence()
    
    func testAddConversation() throws {
        guard let activity = try persistence.activity(withID: 1, measuredFrom: .default),
              let alice = try persistence.user(withID: ObjectId("594d5ccd819a5360859a5360")),
              let charlie = try persistence.user(withID: ObjectId("594d5c76819a5360839a5360")) else {
            return XCTFail()
        }
        let conversation = Conversation(topic: activity, sender: alice, recipient: charlie)
        try persistence.add(conversation)
        guard let id = conversation.id else {
            return XCTFail()
        }
        XCTAssertNotNil(try persistence.conversation(between: alice, charlie, regarding: activity))
        // Clean-up
        try persistence.conversations.remove(["_id": id])
    }
    
    func testAddPersistedConversation() throws {
        guard let activity = try persistence.activity(withID: 1, measuredFrom: .default),
              let bob = try persistence.user(withID: ObjectId("594d65bd819a5360869a5360")),
              let charlie = try persistence.user(withID: ObjectId("594d5c76819a5360839a5360")),
              let conversation = try persistence.conversation(between: bob, charlie, regarding: activity) else {
            return XCTFail()
        }
        XCTAssertThrowsError(try persistence.add(conversation))
    }
    
    func testFindConversation() throws {
        guard let activity = try persistence.activity(withID: 1, measuredFrom: .default),
              let alice = try persistence.user(withID: ObjectId("594d5ccd819a5360859a5360")),
              let bob = try persistence.user(withID: ObjectId("594d65bd819a5360869a5360")),
              let charlie = try persistence.user(withID: ObjectId("594d5c76819a5360839a5360")) else {
            return XCTFail()
        }
        XCTAssertNotNil(try persistence.conversation(between: bob, charlie, regarding: activity))
        XCTAssertNotNil(try persistence.conversation(between: charlie, bob, regarding: activity))
        XCTAssertNil(try persistence.conversation(between: alice, bob, regarding: activity))
    }
    
    func testFindConversationRegardingUnpersistedActivity() throws {
        guard let alice = try persistence.user(withID: ObjectId("594d5ccd819a5360859a5360")),
              let bob = try persistence.user(withID: ObjectId("594d65bd819a5360869a5360")),
              let location = alice.location else {
            return XCTFail()
        }
        let activity = Activity(host: alice,
                                name: "Something to do", game: nil,
                                playerCount: 2...4, prereservedSeats: 1,
                                date: Date(), deadline: Date(),
                                location: location,
                                info: "")
        XCTAssertThrowsError(try persistence.conversation(between: alice, bob, regarding: activity))
    }
    
    func testConversationsForUser() throws {
        guard let alice = try persistence.user(withID: ObjectId("594d5ccd819a5360859a5360")),
              let bob = try persistence.user(withID: ObjectId("594d65bd819a5360869a5360")),
              let location = alice.location else {
            return XCTFail()
        }
        let yesterday = Calendar(identifier: .gregorian).date(byAdding: .hour, value: -12, to: Date())!
        let activityFromYesterday = Activity(host: alice,
                                             name: "Something we did yesterday", game: nil,
                                             playerCount: 2...4, prereservedSeats: 1,
                                             date: yesterday, deadline: yesterday,
                                             location: location,
                                             info: "")
        try persistence.add(activityFromYesterday)
        guard let activityID = activityFromYesterday.id else {
            return XCTFail()
        }
        let conversation = Conversation(topic: activityFromYesterday, sender: alice, recipient: bob)
        conversation.messages.append(Conversation.Message(direction: .outgoing, text: "Hi Bob"))
        try persistence.add(conversation)
        guard let conversationID = conversation.id else {
            return XCTFail()
        }
        let results = try persistence.conversations(for: bob)
        XCTAssert(results.map { $0.id } == [4, 2, 3, conversationID])
        // Clean-up
        try persistence.activities.remove(["_id": activityID])
        try persistence.conversations.remove(["_id": conversationID])
    }
    
    func testUnreadMessageCount() throws {
        guard let alice = try persistence.user(withID: ObjectId("594d5ccd819a5360859a5360")),
              let bob = try persistence.user(withID: ObjectId("594d65bd819a5360869a5360")),
              let location = alice.location else {
            return XCTFail()
        }
        let yesterday = Calendar(identifier: .gregorian).date(byAdding: .hour, value: -12, to: Date())!
        let activityFromYesterday = Activity(host: alice,
                                             name: "Something we did yesterday", game: nil,
                                             playerCount: 2...4, prereservedSeats: 1,
                                             date: yesterday, deadline: yesterday,
                                             location: location,
                                             info: "")
        try persistence.add(activityFromYesterday)
        guard let activityID = activityFromYesterday.id else {
            return XCTFail()
        }
        let conversation = Conversation(topic: activityFromYesterday, sender: alice, recipient: bob)
        conversation.messages.append(Conversation.Message(direction: .outgoing, text: "Hi Bob"))
        try persistence.add(conversation)
        guard let conversationID = conversation.id else {
            return XCTFail()
        }
        XCTAssert(try persistence.unreadMessageCount(for: bob) == 3)
        // Clean-up
        try persistence.activities.remove(["_id": activityID])
        try persistence.conversations.remove(["_id": conversationID])
    }
    
    func testUnreadMessageCountZero() throws {
        guard let charlie = try persistence.user(withID: ObjectId("594d5c76819a5360839a5360")) else {
            return XCTFail()
        }
        XCTAssert(try persistence.unreadMessageCount(for: charlie) == 0)
    }
    
    func testUpdateConversation() throws {
        guard let activity = try persistence.activity(withID: 1, measuredFrom: .default),
              let bob = try persistence.user(withID: ObjectId("594d65bd819a5360869a5360")),
              let charlie = try persistence.user(withID: ObjectId("594d5c76819a5360839a5360")),
              let conversation = try persistence.conversation(between: bob, charlie, regarding: activity) else {
            return XCTFail()
        }
        conversation.messages[1].isRead = true
        try persistence.update(conversation)
        XCTAssert(try persistence.conversation(between: bob, charlie, regarding: activity)?.messages[1].isRead == true)
        // Clean-up
        conversation.messages[1].isRead = false
        try persistence.update(conversation)
    }
    
    func testUpdateUnpersistedConversation() throws {
        guard let activity = try persistence.activity(withID: 1, measuredFrom: .default),
              let alice = try persistence.user(withID: ObjectId("594d5ccd819a5360859a5360")),
              let bob = try persistence.user(withID: ObjectId("594d65bd819a5360869a5360")) else {
            return XCTFail()
        }
        let conversation = Conversation(topic: activity, sender: alice, recipient: bob)
        XCTAssertThrowsError(try persistence.update(conversation))
    }
}
