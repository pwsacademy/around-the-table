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
            ("testNumberOfActivitiesInWindow", testNumberOfActivitiesInWindow),
            ("testNewestActivities", testNewestActivities),
            ("testUpcomingActivities", testUpcomingActivities),
            ("testActivitiesNearUser", testActivitiesNearUser),
            ("testActivitiesNearUserWithoutLocation", testActivitiesNearUserWithoutLocation),
            ("testHostsJoinedBy", testHostsJoinedBy),
            ("testActivitiesHostedBy", testActivitiesHostedBy),
            ("testActivitiesJoinedBy", testActivitiesJoinedBy),
            ("testUpdateActivity", testUpdateActivity),
            ("testUpdateUnpersistedActivity", testUpdateUnpersistedActivity)
        ]
    }
    
    private let persistence = try! Persistence()
    
    // Don't use Settings.calendar and Settings.timeZone here to ensure that
    // the result of the test does not depend on the configured time zone.
    private let timeZone = TimeZone(identifier: "Europe/London")!
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()
    
    /*
     The one-month window for the test database starts on Feb. 1 2100.
     */
    private var today: Date {
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.day = 1
        dateComponents.month = 2
        dateComponents.year = 2100
        dateComponents.hour = 8
        dateComponents.minute = 0
        dateComponents.timeZone = timeZone
        return calendar.date(from: dateComponents)!
    }
    
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
    
    func testNumberOfActivitiesInWindow() throws {
        XCTAssert(try persistence.numberOfActivities(inWindowFrom: today) == 3)
    }
    
    func testNewestActivities() throws {
        let result = try persistence.newestActivities(inWindowFrom: today, measuredFrom: .default)
        XCTAssert(result.map { $0.id } == [1, 4, 2])
    }
    
    func testUpcomingActivities() throws {
        let result = try persistence.upcomingActivities(inWindowFrom: today, measuredFrom: .default)
        XCTAssert(result.map { $0.id } == [1, 2, 4])
    }
    
    func testActivitiesNearUser() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        let result = try persistence.activitiesNear(user: bob, inWindowFrom: today)
        XCTAssert(result.map { $0.id } == [2, 4, 1])
    }
    
    func testActivitiesNearUserWithoutLocation() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        bob.location = nil
        XCTAssertThrowsError(try persistence.activitiesNear(user: bob, inWindowFrom: today))
    }
    
    func testHostsJoinedBy() throws {
        guard let bob = try persistence.user(withID: 2),
              let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        let result = try persistence.hostsJoined(by: bob, inWindowFrom: today)
        XCTAssert(result == [charlie])
    }
    
    func testActivitiesHostedBy() throws {
        guard let alice = try persistence.user(withID: 1),
              let location = alice.location else {
            return XCTFail()
        }
        let yesterday = calendar.date(byAdding: .hour, value: -12, to: Date())!
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
        XCTAssert(result.map { $0.id } == [id, 2, 4, 6])
        // Clean-up
        try persistence.activities.remove(["_id": id])
    }
    
    func testActivitiesJoinedBy() throws {
        guard let alice = try persistence.user(withID: 1),
              let bob = try persistence.user(withID: 2),
              let location = alice.location else {
            return XCTFail()
        }
        let yesterday = calendar.date(byAdding: .hour, value: -12, to: Date())!
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
        XCTAssert(result.map { $0.id } == [id, 1, 6])
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
