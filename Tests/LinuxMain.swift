import XCTest
@testable import AroundTheTableTests

XCTMain([
    testCase(ExtensionsTests.allTests),
    // Models
    testCase(ActivityTests.allTests),
    testCase(ActivityRegistrationTests.allTests),
    testCase(BSONExtensionsTests.allTests),
    testCase(CodableExtensionsTests.allTests),
    testCase(ConversationTests.allTests),
    testCase(ConversationMessageTests.allTests),
    testCase(CoordinatesTests.allTests),
    testCase(GameTests.allTests),
    testCase(LocationTests.allTests),
    testCase(UserTests.allTests),
    // Persistence
    testCase(GameRepositoryTests.allTests),
    testCase(UserRepositoryTests.allTests)
])
