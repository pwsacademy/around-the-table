import XCTest
@testable import AroundTheTable

class CodableExtensionsTests: XCTestCase {
    
    static var allTests: [(String, (CodableExtensionsTests) -> () throws -> Void)] {
        return [
            ("testEncodeClosedRange", testEncodeClosedRange),
            ("testDecodeClosedRange", testDecodeClosedRange)
        ]
    }
    
    /* ClosedRange */
    
    func testEncodeClosedRange() throws {
        let input = 2...4
        let result = try JSONEncoder().encode(input)
        let resultAsDictionary = try JSONDecoder().decode([String: Int].self, from: result)
        let expected = [
            "lowerBound": 2,
            "upperBound": 4
        ]
        XCTAssert(resultAsDictionary == expected)
    }
    
    func testDecodeClosedRange() throws {
        let input = try JSONEncoder().encode([
            "lowerBound": 2,
            "upperBound": 4
        ])
        let result = try JSONDecoder().decode(ClosedRange<Int>.self, from: input)
        XCTAssert(result == 2...4)
    }
}
