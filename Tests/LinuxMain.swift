import XCTest
@testable import AroundTheTableTests

XCTMain([
    testCase(ExtensionsTests.allTests),
    testCase(StencilFiltersTests.allTests),
    // Models
    testCase(ActivityTests.allTests),
    testCase(ActivityRegistrationTests.allTests),
    testCase(BSONExtensionsTests.allTests),
    testCase(ConversationTests.allTests),
    testCase(ConversationMessageTests.allTests),
    testCase(CoordinatesTests.allTests),
    testCase(GameTests.allTests),
    testCase(LocationTests.allTests),
    testCase(NotificationTests.allTests),
    testCase(UserTests.allTests),
    testCase(SponsorTests.allTests),
    // Persistence
    testCase(ActivityRepositoryTests.allTests),
    testCase(ConversationRepositoryTests.allTests),
    testCase(CredentialsRepositoryTests.allTests),
    testCase(GameRepositoryTests.allTests),
    testCase(NotificationRepositoryTests.allTests),
    testCase(SponsorRepositoryTests.allTests),
    testCase(UserRepositoryTests.allTests),
    // Middleware
    testCase(ForwardingMiddlewareTests.allTests),
    // Routes
    testCase(RoutesTests.allTests),
    // Services
    testCase(CloudObjectStorageTests.allTests)
])
