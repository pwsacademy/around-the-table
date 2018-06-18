import BSON
import XCTest
@testable import AroundTheTable

class UserTests: XCTestCase {
    
    static var allTests: [(String, (UserTests) -> () throws -> Void)] {
        return [
            ("testEncode", testEncode),
            ("testEncodeSkipsNilValues", testEncodeSkipsNilValues),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingID", testDecodeMissingID),
            ("testDecodeMissingName", testDecodeMissingName),
            ("testDecodeMissingLastSignIn", testDecodeMissingLastSignIn)
        ]
    }
    
    private let url = URL(string: "http://github.com/")!
    private let location = Location(coordinates: Coordinates(latitude: 50, longitude: 2),
                                    address: "Street 1", city: "City", country: "Country")
    private let now = Date()
    
    func testEncode() {
        let input = User(id: "123", name: "User", picture: url, location: location)
        input.lastSignIn = now
        let expected: Document = [
            "_id": "123",
            "name": "User",
            "picture": url,
            "location": location,
            "lastSignIn": now
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testEncodeSkipsNilValues() {
        let input = User(id: "123", name: "User")
        input.lastSignIn = now
        let expected: Document = [
            "_id": "123",
            "name": "User",
            "lastSignIn": now
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "_id": "123",
            "name": "User",
            "picture": url,
            "location": location,
            "lastSignIn": now
        ]
        guard let result = try User(input) else {
            return XCTFail()
        }
        XCTAssert(result.id == "123")
        XCTAssert(result.name == "User")
        XCTAssert(result.picture == url)
        XCTAssert(result.location == location)
        assertDatesEqual(result.lastSignIn, now)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = "123"
        let result = try User(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingID() {
        let input: Document = [
            "name": "User",
            "lastSignIn": now
        ]
        XCTAssertThrowsError(try User(input))
    }
    
    func testDecodeMissingName() {
        let input: Document = [
            "_id": "123",
            "lastSignIn": now
        ]
        XCTAssertThrowsError(try User(input))
    }
    
    func testDecodeMissingLastSignIn() {
        let input: Document = [
            "_id": "123",
            "name": "User"
        ]
        XCTAssertThrowsError(try User(input))
    }
}
