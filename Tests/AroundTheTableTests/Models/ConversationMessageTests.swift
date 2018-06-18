import BSON
import XCTest
@testable import AroundTheTable

class ConversationMessageTests: XCTestCase {
    
    static var allTests: [(String, (ConversationMessageTests) -> () throws -> Void)] {
        return [
            ("testInitializationValues", testInitializationValues),
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingTimestamp", testDecodeMissingTimestamp),
            ("testDecodeInvalidDirection", testDecodeInvalidDirection),
            ("testDecodeMissingText", testDecodeMissingText),
            ("testDecodeMissingIsRead", testDecodeMissingIsRead)
        ]
    }
    
    private let now = Date()
    
    func testInitializationValues() {
        let message = Conversation.Message(direction: .outgoing, text: "Hello")
        XCTAssertFalse(message.isRead)
    }
    
    func testEncode() {
        let input = Conversation.Message(direction: .outgoing, text: "Hello")
        let expected: Document = [
            "timestamp": input.timestamp,
            "direction": "outgoing",
            "text": "Hello",
            "isRead": false
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "timestamp": now,
            "direction": "outgoing",
            "text": "Hello",
            "isRead": false
        ]
        guard let result = try Conversation.Message(input) else {
            return XCTFail()
        }
        assertDatesEqual(result.timestamp, now)
        XCTAssert(result.direction == .outgoing)
        XCTAssert(result.text == "Hello")
        XCTAssertFalse(result.isRead)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = "Hello"
        let result = try Conversation.Message(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingTimestamp() {
        let input: Document = [
            "direction": "outgoing",
            "text": "Hello",
            "isRead": false
        ]
        XCTAssertThrowsError(try Conversation.Message(input))
    }
    
    func testDecodeInvalidDirection() {
        let input: Document = [
            "timestamp": now,
            "direction": "out",
            "text": "Hello",
            "isRead": false
        ]
        XCTAssertThrowsError(try Conversation.Message(input))
    }
    
    func testDecodeMissingText() {
        let input: Document = [
            "timestamp": now,
            "direction": "outgoing",
            "isRead": false
        ]
        XCTAssertThrowsError(try Conversation.Message(input))
    }
    
    func testDecodeMissingIsRead() {
        let input: Document = [
            "timestamp": now,
            "direction": "outgoing",
            "text": "Hello"
        ]
        XCTAssertThrowsError(try Conversation.Message(input))
    }
}
