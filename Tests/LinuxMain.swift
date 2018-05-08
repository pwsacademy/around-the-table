import XCTest
@testable import AroundTheTableTests

XCTMain([
    testCase(BSONExtensionsTests.allTests),
    testCase(CodableExtensionsTests.allTests)
])
