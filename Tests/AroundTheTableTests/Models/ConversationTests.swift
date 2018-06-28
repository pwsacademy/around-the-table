import BSON
import XCTest
@testable import AroundTheTable

class ConversationTests: XCTestCase {
    
    static var allTests: [(String, (ConversationTests) -> () throws -> Void)] {
        return [
            ("testInitializationValues", testInitializationValues),
            ("testFactoryMethodsAddMessage", testFactoryMethodsAddMessage),
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingID", testDecodeMissingID),
            ("testDecodeTopicNotDenormalized", testDecodeTopicNotDenormalized),
            ("testDecodeSenderNotDenormalized", testDecodeSenderNotDenormalized),
            ("testDecodeRecipientNotDenormalized", testDecodeRecipientNotDenormalized),
            ("testDecodeMissingMessages", testDecodeMissingMessages)
        ]
    }
    
    private let id = ObjectId("5ac8f06e5027834a5027834a")!
    private let now = Date()
    private let message = Conversation.Message(direction: .outgoing, text: "Hello")
    
    private var host: User {
        let user = User(facebookID: "1", name: "Host")
        user.id = ObjectId("594d5ccd819a5360859a5360")!
        return user
    }
    
    private var player: User {
        let user = User(facebookID: "2", name: "Player")
        user.id = ObjectId("594d65bd819a5360869a5360")!
        return user
    }
    
    private var activity: Activity {
        let activity = Activity(host: host,
                                name: "Game", game: nil,
                                playerCount: 2...4, prereservedSeats: 1,
                                date: now, deadline: now,
                                location: Location(coordinates: Coordinates(latitude: 50, longitude: 2),
                                                   address: "Street 1", city: "City", country: "Country"),
                                info: "")
        activity.id = ObjectId("594d5bef819a5360829a5360")!
        return activity
    }
    
    func testInitializationValues() {
        let conversation = Conversation(topic: activity, sender: player, recipient: host)
        XCTAssert(conversation.messages.isEmpty)
    }
    
    func testFactoryMethodsAddMessage() {
        for method in [Conversation.hostApprovedRegistration,
                       Conversation.hostCancelledActivity,
                       Conversation.hostCancelledRegistration,
                       Conversation.hostChangedAddress,
                       Conversation.hostChangedDate] {
            let conversation = Conversation(topic: activity, sender: host, recipient: player)
            method(conversation)()
            XCTAssert(conversation.messages.count == 1)
            XCTAssert(conversation.messages[0].direction == .outgoing)
        }
        for method in [Conversation.playerCancelledRegistration,
                       Conversation.playerSentRegistration] {
            let conversation = Conversation(topic: activity, sender: player, recipient: host)
            method(conversation)()
            XCTAssert(conversation.messages.count == 1)
            XCTAssert(conversation.messages[0].direction == .outgoing)
        }
    }
    
    func testEncode() {
        let input = Conversation(topic: activity, sender: host, recipient: player)
        input.id = id
        input.messages.append(message)
        let expected: Document = [
            "_id": id,
            "topic": activity.id,
            "sender": host.id,
            "recipient": player.id,
            "messages": [ message ]
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        var input: Document = [
            "_id": id,
            "topic": activity,
            "sender": host,
            "recipient": player,
            "messages": [ message ]
        ]
        input["topic"]["host"] = host
        guard let result = try Conversation(input) else {
            return XCTFail()
        }
        XCTAssert(result.id == id)
        XCTAssert(result.topic == activity)
        XCTAssert(result.sender == host)
        XCTAssert(result.recipient == player)
        XCTAssert(result.messages.count == 1)
        assertDatesEqual(result.messages[0].timestamp, message.timestamp)
        XCTAssert(result.messages[0].direction == .outgoing)
        XCTAssert(result.messages[0].text == "Hello")
        XCTAssertFalse(result.messages[0].isRead)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = "Hello"
        let result = try Conversation(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingID() throws {
        var input: Document = [
            "topic": activity,
            "sender": host,
            "recipient": player,
            "messages": [ message ]
        ]
        input["topic"]["host"] = host
        XCTAssertThrowsError(try Conversation(input))
    }
    
    func testDecodeTopicNotDenormalized() throws {
        let input: Document = [
            "_id": id,
            "topic": activity.id,
            "sender": host,
            "recipient": player,
            "messages": [ message ]
        ]
        XCTAssertThrowsError(try Conversation(input))
    }
    
    func testDecodeSenderNotDenormalized() throws {
        var input: Document = [
            "_id": id,
            "topic": activity,
            "sender": host.id,
            "recipient": player,
            "messages": [ message ]
        ]
        input["topic"]["host"] = host
        XCTAssertThrowsError(try Conversation(input))
    }
    
    func testDecodeRecipientNotDenormalized() throws {
        var input: Document = [
            "_id": id,
            "topic": activity,
            "sender": host,
            "recipient": player.id,
            "messages": [ message ]
        ]
        input["topic"]["host"] = host
        XCTAssertThrowsError(try Conversation(input))
    }
    
    func testDecodeMissingMessages() throws {
        var input: Document = [
            "_id": id,
            "topic": activity,
            "sender": host,
            "recipient": player
        ]
        input["topic"]["host"] = host
        XCTAssertThrowsError(try Conversation(input))
    }
}
