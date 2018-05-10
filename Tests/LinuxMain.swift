import XCTest
@testable import AroundTheTableTests

XCTMain([
    // Models
    testCase(ActivityTests.allTests),
    testCase(ActivityRegistrationTests.allTests),
    testCase(BSONExtensionsTests.allTests),
    testCase(CodableExtensionsTests.allTests),
    testCase(CoordinatesTests.allTests),
    testCase(GameTests.allTests),
    testCase(LocationTests.allTests),
    testCase(UserTests.allTests)
])
