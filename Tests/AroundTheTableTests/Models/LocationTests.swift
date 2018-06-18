import BSON
import XCTest
@testable import AroundTheTable

class LocationTests: XCTestCase {
    
    static var allTests: [(String, (LocationTests) -> () throws -> Void)] {
        return [
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingCoordinates", testDecodeMissingCoordinates),
            ("testDecodeMissingAddress", testDecodeMissingAddress),
            ("testDecodeMissingCity", testDecodeMissingCity),
            ("testDecodeMissingCountry", testDecodeMissingCountry)
        ]
    }
    
    private let coordinates = Coordinates(latitude: 50, longitude: 2)
    
    func testEncode() {
        let input = Location(coordinates: coordinates, address: "Street 1", city: "City", country: "BE")
        let expected: Document = [
            "coordinates": coordinates,
            "address": "Street 1",
            "city": "City",
            "country": "BE"
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "coordinates": coordinates,
            "address": "Street 1",
            "city": "City",
            "country": "BE"
        ]
        let result = try Location(input)
        let expected = Location(coordinates: coordinates, address: "Street 1", city: "City", country: "BE")
        XCTAssert(result == expected)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = "(50, 2)"
        let result = try Location(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingCoordinates() {
        let input: Document = [
            "address": "Street 1",
            "city": "City",
            "country": "BE"
        ]
        XCTAssertThrowsError(try Location(input))
    }
    
    func testDecodeMissingAddress() {
        let input: Document = [
            "coordinates": coordinates,
            "city": "City",
            "country": "BE"
        ]
        XCTAssertThrowsError(try Location(input))
    }
    
    func testDecodeMissingCity() {
        let input: Document = [
            "coordinates": coordinates,
            "address": "Street 1",
            "country": "BE"
        ]
        XCTAssertThrowsError(try Location(input))
    }
    
    func testDecodeMissingCountry() {
        let input: Document = [
            "coordinates": coordinates,
            "address": "Street 1",
            "city": "City"
        ]
        XCTAssertThrowsError(try Location(input))
    }
}
