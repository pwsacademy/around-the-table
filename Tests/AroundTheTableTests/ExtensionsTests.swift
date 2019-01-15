import Foundation
import XCTest
@testable import AroundTheTable

class ExtensionsTests: XCTestCase {
    
    /*
     testLastDayInWindowWithJumpToSmallerMonth is commented out due to https://bugs.swift.org/browse/SR-9668.
     testFormattedDateAndTime is commented out due to https://bugs.swift.org/browse/SR-1325.
     */
    static var allTests: [(String, (ExtensionsTests) -> () throws -> Void)] {
        return [
            ("testDay", testDay),
            ("testMonth", testMonth),
            ("testYear", testYear),
            ("testPreviousDay", testPreviousDay),
            ("testPreviousDayWithFirstOfMonth", testPreviousDayWithFirstOfMonth),
            ("testLastDayInWindowWithFirstOfMonth", testLastDayInWindowWithFirstOfMonth),
            ("testLastDayInWindowWithRegularDate", testLastDayInWindowWithRegularDate),
//            ("testLastDayInWindowWithJumpToSmallerMonth", testLastDayInWindowWithJumpToSmallerMonth),
//            ("testFormattedDateAndTime", testFormattedDateAndTime),
            ("testFormattedDateAndTimeWithFormat", testFormattedDateAndTimeWithFormat)
        ]
    }
    
    /* Date */
    
    private let calendar = Calendar(identifier: .gregorian)
    
    private var firstOfMonth: Date {
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.day = 1
        dateComponents.month = 1
        dateComponents.year = 2019
        dateComponents.timeZone = Settings.timeZone
        return calendar.date(from: dateComponents)!
    }
    
    private var regularDate: Date {
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.day = 2
        dateComponents.month = 1
        dateComponents.year = 2019
        dateComponents.timeZone = Settings.timeZone
        return calendar.date(from: dateComponents)!
    }
    
    private var lastOfMonth: Date {
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.day = 31
        dateComponents.month = 1
        dateComponents.year = 2019
        dateComponents.timeZone = Settings.timeZone
        return calendar.date(from: dateComponents)!
    }
    
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
    
    func testLastDayInWindowWithFirstOfMonth() {
        let result = firstOfMonth.lastDayInWindow
        XCTAssert(result.day == 31)
        XCTAssert(result.month == 1)
        XCTAssert(result.year == 2019)
    }
    
    func testLastDayInWindowWithRegularDate() {
        let result = regularDate.lastDayInWindow
        XCTAssert(result.day == 1)
        XCTAssert(result.month == 2)
        XCTAssert(result.year == 2019)
    }
    
    func testLastDayInWindowWithJumpToSmallerMonth() {
        let result = lastOfMonth.lastDayInWindow
        XCTAssert(result.day == 28)
        XCTAssert(result.month == 2)
        XCTAssert(result.year == 2019)
    }
    
    private let locale = Locale(identifier: "nl_BE")
    private let timeZone = TimeZone(identifier: "Europe/Brussels")!
    
    private var localDate: Date {
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
        print(result)
        XCTAssert(result == "dinsdag 22 november 18:00")
    }
}
