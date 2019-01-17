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
            ("testAddExistingConversation", testAddExistingConversation),
            ("testAddConflictingConversation", testAddConflictingConversation),
            ("testFindConversation", testFindConversation),
            ("testConversationsForUser", testConversationsForUser),
            ("testUnreadMessageCount", testUnreadMessageCount),
            ("testUpdateConversation", testUpdateConversation),
            ("testUpdateUnpersistedConversation", testUpdateUnpersistedConversation)
        ]
    }
    
    let persistence = try! Persistence()
    
    func testAddConversation() throws {
        guard let alice = try persistence.user(withID: 1),
              let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        let conversation = Conversation(sender: alice, recipient: charlie)
        try persistence.add(conversation)
        guard let id = conversation.id else {
            return XCTFail()
        }
        XCTAssertNotNil(try persistence.conversation(between: alice, charlie))
        // Clean-up
        try persistence.conversations.remove(["_id": id])
    }
    
    func testAddExistingConversation() throws {
        guard let bob = try persistence.user(withID: 2),
              let charlie = try persistence.user(withID: 3),
              let conversation = try persistence.conversation(between: bob, charlie) else {
            return XCTFail()
        }
        XCTAssertThrowsError(try persistence.add(conversation))
    }
    
    func testAddConflictingConversation() throws {
        guard let bob = try persistence.user(withID: 2),
              let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        let conversation = Conversation(sender: bob, recipient: charlie)
        XCTAssertThrowsError(try persistence.add(conversation))
    }
    
    func testFindConversation() throws {
        guard let alice = try persistence.user(withID: 1),
              let bob = try persistence.user(withID: 2),
              let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        XCTAssertNotNil(try persistence.conversation(between: alice, bob))
        XCTAssertNotNil(try persistence.conversation(between: bob, charlie))
        XCTAssertNil(try persistence.conversation(between: alice, charlie))
    }
    
    func testConversationsForUser() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        let results = try persistence.conversations(for: bob)
        XCTAssert(results.map { $0.id } == [2, 1])
    }
    
    func testUnreadMessageCount() throws {
        guard let alice = try persistence.user(withID: 1),
              let bob = try persistence.user(withID: 2),
              let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        XCTAssert(try persistence.unreadMessageCount(for: alice) == 0)
        XCTAssert(try persistence.unreadMessageCount(for: bob) == 2)
        XCTAssert(try persistence.unreadMessageCount(for: charlie) == 0)
    }

    func testUpdateConversation() throws {
        guard let bob = try persistence.user(withID: 2),
              let charlie = try persistence.user(withID: 3),
              let conversation = try persistence.conversation(between: bob, charlie) else {
            return XCTFail()
        }
        conversation.messages[1].isRead = true
        try persistence.update(conversation)
        XCTAssert(try persistence.unreadMessageCount(for: bob) == 1)
        // Clean-up
        conversation.messages[1].isRead = false
        try persistence.update(conversation)
    }
    
    func testUpdateUnpersistedConversation() throws {
        guard let alice = try persistence.user(withID: 1),
              let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        let conversation = Conversation(sender: alice, recipient: bob)
        XCTAssertThrowsError(try persistence.update(conversation))
    }
}
