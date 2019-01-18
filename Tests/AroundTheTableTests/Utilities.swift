import Foundation
import XCTest
@testable import AroundTheTable

/**
 Asserts that two dates are equal.
 
 This function allows for sub-millisecond differences that result from floating-point rounding errors.
 */
func assertDatesEqual(_ date1: Date, _ date2: Date) {
    XCTAssert(abs(date1.timeIntervalSince(date2)) < 0.001)
}

/**
 Creates a date from the given date components.
 
 Uses `Settings.timeZone` and `Settings.calendar`.
 */
func dateFromComponents(day: Int, month: Int, year: Int, hour: Int = 0, minute: Int = 0) -> Date {
    var dateComponents = DateComponents()
    dateComponents.calendar = Settings.calendar
    dateComponents.day = day
    dateComponents.month = month
    dateComponents.year = year
    dateComponents.hour = hour
    dateComponents.minute = minute
    dateComponents.timeZone = Settings.timeZone
    return Settings.calendar.date(from: dateComponents)!
}

/**
 Loads a file from the **Fixtures** directory.
 */
func loadFixture(file: String) -> Data? {
    var basePath = Array(#file.components(separatedBy: "/").dropLast())
    basePath += ["Fixtures", file]
    let path = basePath.joined(separator: "/")
    return FileManager.default.contents(atPath: path)
}
