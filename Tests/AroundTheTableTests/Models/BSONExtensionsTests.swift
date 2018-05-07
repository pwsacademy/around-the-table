import BSON
import XCTest
@testable import AroundTheTable

class BSONCodableTests: XCTestCase {
    
    /* CountableClosedRange */
    
    func testEncodeCountableClosedRange() {
        let input = 1...10
        let expected: Document = [
            "lowerBound": 1,
            "upperBound": 10
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecodeCountableClosedRange() throws {
        let input: Document = [
            "lowerBound": 1,
            "upperBound": 10
        ]
        let result = try CountableClosedRange<Int>(input)
        XCTAssert(result == 1...10)
    }
    
    func testDecodeCountableClosedRangeNotADocument() throws {
        let input = "1...10"
        let result = try CountableClosedRange<Int>(input)
        XCTAssertNil(result)
    }
    
    func testDecodeCountableClosedRangeMissingLowerBound() {
        let input: Document = [
            "upperBound": 10
        ]
        XCTAssertThrowsError(try CountableClosedRange<Int>(input))
    }
    
    func testDecodeCountableClosedRangeMissingUpperBound() {
        let input: Document = [
            "lowerBound": 1
        ]
        XCTAssertThrowsError(try CountableClosedRange<Int>(input))
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
