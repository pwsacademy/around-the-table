import XCTest
@testable import AroundTheTable

class StencilFiltersTests: XCTestCase {
    
    static var allTests: [(String, (StencilFiltersTests) -> () throws -> Void)] {
        return [
            ("testCountInt", testCountInt),
            ("testCountString", testCountString),
            ("testCountNotAnArray", testCountNotAnArray),
            ("testFirstInt", testFirstInt),
            ("testFirstString", testFirstString),
            ("testFirstNotAnArray", testFirstNotAnArray),
            ("testMaxInt", testMaxInt),
            ("testMaxNotAnIntArray", testMaxNotAnIntArray),
            ("testPrevious", testPrevious),
            ("testPreviousNotAnInt", testPreviousNotAnInt),
            ("testNext", testNext),
            ("testNextNotAnInt", testNextNotAnInt)
        ]
    }
    
    func testCountInt() {
        let input = [1, 2, 3, 4]
        let result = StencilFilters.count(input) as? Int
        XCTAssert(result == 4)
    }
    
    func testCountString() {
        let input = ["1", "2", "3", "4"]
        let result = StencilFilters.count(input) as? Int
        XCTAssert(result == 4)
    }
    
    func testCountNotAnArray() {
        let input = "1, 2, 3, 4"
        let result = StencilFilters.count(input) as? Int
        XCTAssertNil(result)
    }
    
    func testFirstInt() {
        let input = [1, 2, 3, 4]
        let result = StencilFilters.first(input) as? Int
        XCTAssert(result == 1)
    }
    
    func testFirstString() {
        let input = ["1", "2", "3", "4"]
        let result = StencilFilters.first(input) as? String
        XCTAssert(result == "1")
    }
    
    func testFirstNotAnArray() {
        let input = "1, 2, 3, 4"
        let result = StencilFilters.first(input) as? String
        XCTAssertNil(result)
    }
    
    func testMaxInt() {
        let input = [1, 2, 3, 4]
        let result = StencilFilters.max(input) as? Int
        XCTAssert(result == 4)
    }
    
    func testMaxNotAnIntArray() {
        let input = ["1", "2", "3", "4"]
        let result = StencilFilters.max(input) as? String
        XCTAssertNil(result)
    }
    
    func testPrevious() {
        let input = 2
        let result = StencilFilters.previous(input) as? Int
        XCTAssert(result == 1)
    }
    
    func testPreviousNotAnInt() {
        let input = 3.0
        let result = StencilFilters.previous(input) as? Double
        XCTAssertNil(result)
    }
    
    func testNext() {
        let input = 2
        let result = StencilFilters.next(input) as? Int
        XCTAssert(result == 3)
    }
    
    func testNextNotAnInt() {
        let input = 3.0
        let result = StencilFilters.next(input) as? Double
        XCTAssertNil(result)
    }
}
