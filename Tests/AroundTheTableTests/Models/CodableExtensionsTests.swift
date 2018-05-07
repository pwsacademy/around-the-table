import XCTest
@testable import AroundTheTable

class CodableExtensionsTests: XCTestCase {
    
    /* CountableClosedRange */
    
    func testEncodeCountableClosedRange() throws {
        let input = 2...4
        let result = try JSONEncoder().encode(input)
        let expected = try JSONEncoder().encode([
            "lowerBound": 2,
            "upperBound": 4
        ])
        XCTAssert(result == expected)
    }
    
    func testDecodeCountableClosedRange() throws {
        let input = try JSONEncoder().encode([
            "lowerBound": 2,
            "upperBound": 4
        ])
        let result = try JSONDecoder().decode(CountableClosedRange<Int>.self, from: input)
        XCTAssert(result == 2...4)
    }
}
