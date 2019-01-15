import BSON
import XCTest
@testable import AroundTheTable

class NotificationTests: XCTestCase {
    
    static var allTests: [(String, (NotificationTests) -> () throws -> Void)] {
        return [
            ("testInitializationValues", testInitializationValues),
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingID", testDecodeMissingID),
            ("testDecodeRecipientNotDenormalized", testDecodeRecipientNotDenormalized),
            ("testDecodeMissingMessage", testDecodeMissingMessage),
            ("testDecodeMissingLink", testDecodeMissingLink),
            ("testDecodeMissingIsRead", testDecodeMissingIsRead)
        ]
    }
    
    private let now = Date()
    private var recipient = User(id: 1, name: "Recipient")
    
    func testInitializationValues() {
        let notification = Notification(timestamp: now, recipient: recipient, message: "Test", link: "activity/1")
        XCTAssertFalse(notification.isRead)
    }
    
    func testEncode() {
        let input = Notification(timestamp: now, recipient: recipient, message: "Test", link: "activity/1", isRead: true)
        let expected: Document = [
            "_id": now,
            "recipient": recipient.id,
            "message": "Test",
            "link": "activity/1",
            "isRead": true
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "_id": now,
            "recipient": recipient,
            "message": "Test",
            "link": "activity/1",
            "isRead": true
        ]
        guard let result = try Notification(input) else {
            return XCTFail()
        }
        assertDatesEqual(result.timestamp, now)
        XCTAssert(result.recipient == recipient)
        XCTAssert(result.message == "Test")
        XCTAssert(result.link == "activity/1")
        XCTAssert(result.isRead)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = now
        let result = try Notification(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingID() {
        let input: Document = [
            "recipient": recipient,
            "message": "Test",
            "link": "activity/1",
            "isRead": true
        ]
        XCTAssertThrowsError(try Notification(input))
    }
    
    func testDecodeRecipientNotDenormalized() {
        let input: Document = [
            "_id": now,
            "recipient": recipient.id,
            "message": "Test",
            "link": "activity/1",
            "isRead": true
        ]
        XCTAssertThrowsError(try Notification(input))
    }
    
    func testDecodeMissingMessage() {
        let input: Document = [
            "_id": now,
            "recipient": recipient,
            "link": "activity/1",
            "isRead": true
        ]
        XCTAssertThrowsError(try Notification(input))
    }
    
    func testDecodeMissingLink() {
        let input: Document = [
            "_id": now,
            "recipient": recipient,
            "message": "Test",
            "isRead": true
        ]
        XCTAssertThrowsError(try Notification(input))
    }
    
    func testDecodeMissingIsRead() throws {
        let input: Document = [
            "_id": now,
            "recipient": recipient,
            "message": "Test",
            "link": "activity/1"
        ]
        XCTAssertThrowsError(try Notification(input))
    }
}
