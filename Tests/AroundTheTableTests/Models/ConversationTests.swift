import BSON
import XCTest
@testable import AroundTheTable

class ConversationTests: XCTestCase {
    
    static var allTests: [(String, (ConversationTests) -> () throws -> Void)] {
        return [
            ("testInitializationValues", testInitializationValues),
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingID", testDecodeMissingID),
            ("testDecodeSenderNotDenormalized", testDecodeSenderNotDenormalized),
            ("testDecodeRecipientNotDenormalized", testDecodeRecipientNotDenormalized),
            ("testDecodeMissingMessages", testDecodeMissingMessages)
        ]
    }
    
    private let message = Conversation.Message(direction: .outgoing, text: "Hello")
    private var host = User(id: 1, name: "Host")
    private var player = User(id: 2, name: "Player")

    func testInitializationValues() {
        let conversation = Conversation(sender: player, recipient: host)
        XCTAssertNil(conversation.id)
        XCTAssert(conversation.messages.isEmpty)
    }
    
    func testEncode() {
        let input = Conversation(id: 1, sender: host, recipient: player, messages: [message])
        let expected: Document = [
            "_id": 1,
            "sender": host.id,
            "recipient": player.id,
            "messages": [message]
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "_id": 1,
            "sender": host,
            "recipient": player,
            "messages": [message]
        ]
        guard let result = try Conversation(input) else {
            return XCTFail()
        }
        XCTAssert(result.id == 1)
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
        let input: Document = [
            "sender": host,
            "recipient": player,
            "messages": [message]
        ]
        XCTAssertThrowsError(try Conversation(input))
    }

    func testDecodeSenderNotDenormalized() throws {
        let input: Document = [
            "_id": 1,
            "sender": host.id,
            "recipient": player,
            "messages": [message]
        ]
        XCTAssertThrowsError(try Conversation(input))
    }
    
    func testDecodeRecipientNotDenormalized() throws {
        let input: Document = [
            "_id": 1,
            "sender": host,
            "recipient": player.id,
            "messages": [message]
        ]
        XCTAssertThrowsError(try Conversation(input))
    }
    
    func testDecodeMissingMessages() throws {
        let input: Document = [
            "_id": 1,
            "sender": host,
            "recipient": player
        ]
        XCTAssertThrowsError(try Conversation(input))
    }
}
