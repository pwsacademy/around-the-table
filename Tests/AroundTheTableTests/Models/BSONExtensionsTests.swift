import BSON
import XCTest
@testable import AroundTheTable

class BSONExtensionsTests: XCTestCase {
    
    static var allTests: [(String, (BSONExtensionsTests) -> () throws -> Void)] {
        return [
            ("testEncodeClosedRange", testEncodeClosedRange),
            ("testDecodeClosedRange", testDecodeClosedRange),
            ("testDecodeClosedRangeNotADocument", testDecodeClosedRangeNotADocument),
            ("testDecodeClosedRangeMissingLowerBound", testDecodeClosedRangeMissingLowerBound),
            ("testDecodeClosedRangeMissingUpperBound", testDecodeClosedRangeMissingUpperBound),
            ("testEncodeURL", testEncodeURL),
            ("testDecodeURL", testDecodeURL),
            ("testDecodeURLNotAString", testDecodeURLNotAString)
        ]
    }
    
    /* ClosedRange */
    
    func testEncodeClosedRange() {
        let input = 1...10
        let expected: Document = [
            "lowerBound": 1,
            "upperBound": 10
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecodeClosedRange() throws {
        let input: Document = [
            "lowerBound": 1,
            "upperBound": 10
        ]
        let result = try ClosedRange<Int>(input)
        XCTAssert(result == 1...10)
    }
    
    func testDecodeClosedRangeNotADocument() throws {
        let input = "1...10"
        let result = try ClosedRange<Int>(input)
        XCTAssertNil(result)
    }
    
    func testDecodeClosedRangeMissingLowerBound() {
        let input: Document = [
            "upperBound": 10
        ]
        XCTAssertThrowsError(try ClosedRange<Int>(input))
    }
    
    func testDecodeClosedRangeMissingUpperBound() {
        let input: Document = [
            "lowerBound": 1
        ]
        XCTAssertThrowsError(try ClosedRange<Int>(input))
    }
    
    /* URL */
    
    func testEncodeURL() {
        let input = URL(string: "http://github.com")!
        let expected = "http://github.com"
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.makeBinary() == expected.makeBinary())
    }
    
    func testDecodeURL() throws {
        let input: Primitive = "http://github.com"
        let result = try URL(input)
        XCTAssert(result == URL(string: "http://github.com"))
    }
    
    func testDecodeURLNotAString() throws {
        let input: Primitive = ["url": "http://github.com"]
        let result = try URL(input)
        XCTAssertNil(result)
    }
}
