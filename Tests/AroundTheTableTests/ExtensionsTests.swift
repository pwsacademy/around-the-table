import Foundation
import XCTest
@testable import AroundTheTable

class ExtensionsTests: XCTestCase {
    
    /*
     testFormattedDateAndTime is commented out due to https://bugs.swift.org/browse/SR-1325.
     */
    static var allTests: [(String, (ExtensionsTests) -> () throws -> Void)] {
        return [
            ("testDay", testDay),
            ("testMonth", testMonth),
            ("testYear", testYear),
            ("testPreviousDay", testPreviousDay),
            ("testPreviousDayWithFirstOfMonth", testPreviousDayWithFirstOfMonth),
            ("testAdding30Days", testAdding30Days),
            ("testSubtracting30Days", testSubtracting30Days),
//            ("testFormattedDateAndTime", testFormattedDateAndTime),
            ("testFormattedDateAndTimeWithFormat", testFormattedDateAndTimeWithFormat)
        ]
    }
    
    /* Date */
        
    private var firstOfMonth = dateFromComponents(day: 1, month: 1, year: 2019)
    private var regularDate = dateFromComponents(day: 2, month: 1, year: 2019)
    private var lastOfMonth = dateFromComponents(day: 31, month: 1, year: 2019)
    
    func testDay() {
        XCTAssert(firstOfMonth.day == 1)
    }
    
    func testMonth() {
        XCTAssert(firstOfMonth.month == 1)
    }
    
    func testYear() {
        XCTAssert(firstOfMonth.year == 2019)
    }
    
    func testPreviousDay() {
        XCTAssert(lastOfMonth.previous.day == 30)
    }
    
    func testPreviousDayWithFirstOfMonth() {
        XCTAssert(firstOfMonth.previous.day == 31)
    }
    
    func testAdding30Days() {
        let result = regularDate.adding30Days
        XCTAssert(result.day == 1)
        XCTAssert(result.month == 2)
        XCTAssert(result.year == 2019)
    }
    
    func testSubtracting30Days() {
        let result = regularDate.subtracting30Days
        XCTAssert(result.day == 3)
        XCTAssert(result.month == 12)
        XCTAssert(result.year == 2018)
    }
    
    private let locale = Locale(identifier: "nl_BE")
    private let timeZone = TimeZone(identifier: "Europe/Brussels")!

    private var localDate: Date {
        // Don't use Settings.calendar and Settings.timeZone here to ensure that
        // the result of the test does not depend on the configured time zone.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.day = 22
        dateComponents.month = 11
        dateComponents.year = 1983
        dateComponents.hour = 18
        dateComponents.minute = 0
        dateComponents.timeZone = timeZone
        return calendar.date(from: dateComponents)!
    }
    
    func testFormattedDateAndTime() {
        let result = localDate.formatted(dateStyle: .full,
                                         timeStyle: .short,
                                         locale: locale,
                                         timeZone: timeZone)
        print(result)
        XCTAssert(result == "dinsdag 22 november 1983 om 18:00")
    }
    
    func testFormattedDateAndTimeWithFormat() {
        let result = localDate.formatted(format: "EEEE d MMMM HH:mm",
                                         locale: locale,
                                         timeZone: timeZone)
        XCTAssert(result == "dinsdag 22 november 18:00")
    }
}
