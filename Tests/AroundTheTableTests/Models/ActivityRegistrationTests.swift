import BSON
import XCTest
@testable import AroundTheTable

class ActivityRegistrationTests: XCTestCase {
    
    static var allTests: [(String, (ActivityRegistrationTests) -> () throws -> Void)] {
        return [
            ("testInitializationValues", testInitializationValues),
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingCreationDate", testDecodeMissingCreationDate),
            ("testDecodePlayerNotDenormalized", testDecodePlayerNotDenormalized),
            ("testDecodeMissingSeats", testDecodeMissingSeats),
            ("testDecodeMissingIsApproved", testDecodeMissingIsApproved),
            ("testDecodeMissingIsCancelled", testDecodeMissingIsCancelled),
        ]
    }
    
    private let now = Date()
    private let player = User(id: "1", name: "Player")
    
    func testInitializationValues() {
        let registration = Activity.Registration(player: player, seats: 1)
        XCTAssertFalse(registration.isApproved)
        XCTAssertFalse(registration.isCancelled)
    }
    
    func testEncode() {
        let input = Activity.Registration(player: player, seats: 1)
        let expected: Document = [
            "creationDate": input.creationDate,
            "player": player.id,
            "seats": 1,
            "isApproved": false,
            "isCancelled": false
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "creationDate": now,
            "player": player,
            "seats": 1,
            "isApproved": false,
            "isCancelled": false
        ]
        guard let result = try Activity.Registration(input) else {
            return XCTFail()
        }
        assertDatesEqual(result.creationDate, now)
        XCTAssert(result.player == player)
        XCTAssert(result.seats == 1)
        XCTAssertFalse(result.isApproved)
        XCTAssertFalse(result.isCancelled)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = now
        let result = try Activity.Registration(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingCreationDate() {
        let input: Document = [
            "player": player,
            "seats": 1,
            "isApproved": false,
            "isCancelled": false
        ]
        XCTAssertThrowsError(try Activity.Registration(input))
    }
    
    func testDecodePlayerNotDenormalized() {
        let input: Document = [
            "creationDate": now,
            "player": player.id,
            "seats": 1,
            "isApproved": false,
            "isCancelled": false
        ]
        XCTAssertThrowsError(try Activity.Registration(input))
    }
    
    func testDecodeMissingSeats() {
        let input: Document = [
            "creationDate": now,
            "player": player,
            "isApproved": false,
            "isCancelled": false
        ]
        XCTAssertThrowsError(try Activity.Registration(input))
    }
    
    func testDecodeMissingIsApproved() {
        let input: Document = [
            "creationDate": now,
            "player": player,
            "seats": 1,
            "isCancelled": false
        ]
        XCTAssertThrowsError(try Activity.Registration(input))
    }
    
    func testDecodeMissingIsCancelled() throws {
        let input: Document = [
            "creationDate": now,
            "player": player,
            "seats": 1,
            "isApproved": false
        ]
        XCTAssertThrowsError(try Activity.Registration(input))
    }
}
