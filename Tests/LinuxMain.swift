import XCTest
@testable import AroundTheTableTests

XCTMain([
    // Models
    testCase(BSONExtensionsTests.allTests),
    testCase(CodableExtensionsTests.allTests),
    testCase(CoordinatesTests.allTests),
    testCase(LocationTests.allTests),
    testCase(UserTests.allTests)
])
