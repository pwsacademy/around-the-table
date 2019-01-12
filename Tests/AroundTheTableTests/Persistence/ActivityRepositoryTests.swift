import BSON
import XCTest
@testable import AroundTheTable

/**
 Run these tests against the **aroundthetable-test** database.
 Import it from **Tests/AroundTheTable/Fixtures/dump**.
 */
class ActivityRepositoryTests: XCTestCase {
    
    static var allTests: [(String, (ActivityRepositoryTests) -> () throws -> Void)] {
        return [
            ("testAddActivity", testAddActivity),
            ("testAddPersistedActivity", testAddPersistedActivity),
            ("testReadActivity", testReadActivity),
            ("testAvailableActivitiesExcludesCancelledAndPast", testAvailableActivitiesExcludesCancelledAndPast),
            ("testAvailableActivitiesWithHostException", testAvailableActivitiesWithHostException),
            ("testNewestActivities", testNewestActivities),
            ("testNewestActivitiesWithHostException", testNewestActivitiesWithHostException),
            ("testUpcomingActivities", testUpcomingActivities),
            ("testUpcomingActivitiesWithHostException", testUpcomingActivitiesWithHostException),
            ("testActivitiesNearUser", testActivitiesNearUser),
            ("testActivitiesNearUserIncludesHostException", testActivitiesNearUserIncludesHostException),
            ("testActivitiesNearUserWithoutLocation", testActivitiesNearUserWithoutLocation),
            ("testActivitiesWithStartAndLimit", testActivitiesWithStartAndLimit),
            ("testActivitiesHostedBy", testActivitiesHostedBy),
            ("testActivitiesJoinedBy", testActivitiesJoinedBy),
            ("testUpdateActivity", testUpdateActivity),
            ("testUpdateUnpersistedActivity", testUpdateUnpersistedActivity)
        ]
    }
    
    let persistence = try! Persistence()
    
    func testAddActivity() throws {
        guard let alice = try persistence.user(withID: 1),
              let location = alice.location else {
            return XCTFail()
        }
        let activity = Activity(host: alice,
                                name: "Something to do", game: nil,
                                playerCount: 2...4, prereservedSeats: 1,
                                date: Date(), deadline: Date(),
                                location: location,
                                info: "")
        try persistence.add(activity)
        guard let id = activity.id else {
            return XCTFail()
        }
        XCTAssertNotNil(try persistence.activity(withID: id, measuredFrom: .default))
        // Clean-up
        try persistence.activities.remove(["_id": id])
    }
    
    func testAddPersistedActivity() throws {
        guard let activity = try persistence.activity(withID: 1, measuredFrom: .default) else {
            return XCTFail()
        }
        XCTAssertThrowsError(try persistence.add(activity))
    }
    
    func testReadActivity() throws {
        for id in 1...5 {
            XCTAssertNotNil(try persistence.activity(withID: id, measuredFrom: .default))
        }
    }
    
    func testAvailableActivitiesExcludesCancelledAndPast() throws {
        XCTAssert(try persistence.numberOfActivities() == 3)
    }
    
    func testAvailableActivitiesWithHostException() throws {
        guard let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        XCTAssert(try persistence.numberOfActivities(notHostedBy: charlie) == 2)
    }
    
    func testNewestActivities() throws {
        let result = try persistence.newestActivities(measuredFrom: .default, startingFrom: 0, limitedTo: .max)
        XCTAssert(result.map { $0.id } == [1, 5, 2])
    }
    
    func testNewestActivitiesWithHostException() throws {
        guard let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        let result = try persistence.newestActivities(notHostedBy: charlie, measuredFrom: .default, startingFrom: 0, limitedTo: .max)
        XCTAssert(result.map { $0.id } == [5, 2])
    }
    
    func testUpcomingActivities() throws {
        let result = try persistence.upcomingActivities(measuredFrom: .default, startingFrom: 0, limitedTo: .max)
        XCTAssert(result.map { $0.id } == [1, 2, 5])
    }
    
    func testUpcomingActivitiesWithHostException() throws {
        guard let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        let result = try persistence.upcomingActivities(notHostedBy: charlie, measuredFrom: .default, startingFrom: 0, limitedTo: .max)
        XCTAssert(result.map { $0.id } == [2, 5])
    }
    
    func testActivitiesNearUser() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        let result = try persistence.activitiesNear(user: bob, startingFrom: 0, limitedTo: .max)
        XCTAssert(result.map { $0.id } == [2, 5, 1])
    }
    
    func testActivitiesNearUserIncludesHostException() throws {
        guard let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        let result = try persistence.activitiesNear(user: charlie, startingFrom: 0, limitedTo: .max)
        XCTAssert(result.map { $0.id } == [2, 5])
    }
    
    func testActivitiesNearUserWithoutLocation() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        bob.location = nil
        XCTAssertThrowsError(try persistence.activitiesNear(user: bob, startingFrom: 0, limitedTo: .max))
    }
    
    func testActivitiesWithStartAndLimit() throws {
        let result = try persistence.newestActivities(measuredFrom: .default, startingFrom: 1, limitedTo: 1)
        XCTAssert(result.map { $0.id } == [5])
    }
    
    func testActivitiesHostedBy() throws {
        guard let alice = try persistence.user(withID: 1),
              let location = alice.location else {
            return XCTFail()
        }
        let yesterday = Calendar(identifier: .gregorian).date(byAdding: .hour, value: -12, to: Date())!
        let activityFromYesterday = Activity(host: alice,
                                             name: "Something we did yesterday", game: nil,
                                             playerCount: 2...4, prereservedSeats: 1,
                                             date: yesterday, deadline: yesterday,
                                             location: location,
                                             info: "")
        try persistence.add(activityFromYesterday)
        guard let id = activityFromYesterday.id else {
            return XCTFail()
        }
        let result = try persistence.activities(hostedBy: alice)
        XCTAssert(result.map { $0.id } == [id, 2, 5])
        // Clean-up
        try persistence.activities.remove(["_id": id])
    }
    
    func testActivitiesJoinedBy() throws {
        guard let alice = try persistence.user(withID: 1),
              let bob = try persistence.user(withID: 2),
              let location = alice.location else {
            return XCTFail()
        }
        let yesterday = Calendar(identifier: .gregorian).date(byAdding: .hour, value: -12, to: Date())!
        let activityFromYesterday = Activity(host: alice,
                                             name: "Something we did yesterday", game: nil,
                                             playerCount: 2...4, prereservedSeats: 1,
                                             date: yesterday, deadline: yesterday,
                                             location: location,
                                             info: "")
        var registration = Activity.Registration(player: bob, seats: 1)
        registration.isApproved = true
        activityFromYesterday.registrations.append(registration)
        try persistence.add(activityFromYesterday)
        guard let id = activityFromYesterday.id else {
            return XCTFail()
        }
        let result = try persistence.activities(joinedBy: bob)
        XCTAssert(result.map { $0.id } == [id, 1])
        // Clean-up
        try persistence.activities.remove(["_id": id])
    }
    
    func testUpdateActivity() throws {
        guard let activity = try persistence.activity(withID: 1, measuredFrom: .default) else {
            return XCTFail()
        }
        XCTAssertFalse(activity.isCancelled)
        activity.isCancelled = true
        try persistence.update(activity)
        XCTAssert(try persistence.activity(withID: 1, measuredFrom: .default)?.isCancelled == true)
        // Clean-up
        activity.isCancelled = false
        try persistence.update(activity)
    }
    
    func testUpdateUnpersistedActivity() throws {
        guard let alice = try persistence.user(withID: 1),
              let location = alice.location else {
            return XCTFail()
        }
        let activity = Activity(host: alice,
                                name: "Something to do", game: nil,
                                playerCount: 2...4, prereservedSeats: 1,
                                date: Date(), deadline: Date(),
                                location: location,
                                info: "")
        XCTAssertThrowsError(try persistence.update(activity))
    }
}
