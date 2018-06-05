import XCTest
@testable import AroundTheTableTests

XCTMain([
    testCase(ExtensionsTests.allTests),
    testCase(StencilFiltersTests.allTests),
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
    testCase(ActivityRepositoryTests.allTests),
    testCase(ConversationRepositoryTests.allTests),
    testCase(GameRepositoryTests.allTests),
    testCase(UserRepositoryTests.allTests),
    // Middleware
    testCase(AuthenticationMiddlewareTests.allTests),
    testCase(ForwardingMiddlewareTests.allTests),
    // Routes
    testCase(RoutesTests.allTests)
])
