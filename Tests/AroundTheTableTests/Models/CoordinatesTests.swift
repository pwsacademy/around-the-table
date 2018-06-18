import BSON
import XCTest
@testable import AroundTheTable

class CoordinatesTests: XCTestCase {
    
    static var allTests: [(String, (CoordinatesTests) -> () throws -> Void)] {
        return [
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingCoordinates", testDecodeMissingCoordinates),
            ("testDecodeInvalidCoordinates", testDecodeInvalidCoordinates)
        ]
    }
    
    func testEncode() {
        let input = Coordinates(latitude: 50, longitude: 2)
        let expected: Document = [
            "type": "Point",
            "coordinates": [ 2.0, 50.0 ]
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(Document(input.point.makePrimitive()) == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "type": "Point",
            "coordinates": [ 2.0, 50.0 ]
        ]
        let result = try Coordinates(input)
        let expected = Coordinates(latitude: 50, longitude: 2)
        XCTAssert(result == expected)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = "(50, 2)"
        let result = try Coordinates(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingCoordinates() {
        let input: Document = [
            "type": "Point",
        ]
        XCTAssertThrowsError(try Coordinates(input))
    }
    
    func testDecodeInvalidCoordinates() {
        let input: Document = [
            "type": "Point",
            "coordinates": [ 2.0 ]
        ]
        XCTAssertThrowsError(try Coordinates(input))
    }
}
