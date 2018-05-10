import Foundation
import XCTest
@testable import AroundTheTable

class ExtensionsTests: XCTestCase {
    
    /*
     One test is commented out due to https://bugs.swift.org/browse/SR-1325.
     */
    static var allTests: [(String, (ExtensionsTests) -> () throws -> Void)] {
        return [
//            ("testFormattedDateAndTime", testFormattedDateAndTime),
            ("testFormattedDateAndTimeWithFormat", testFormattedDateAndTimeWithFormat)
        ]
    }
    
    /* Date */
    
    private let locale = Locale(identifier: "nl_BE")
    private let timeZone = TimeZone(identifier: "Europe/Brussels")!
    
    private var date: Date {
        let calendar = Calendar(identifier: .gregorian)
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
        let result = date.formatted(dateStyle: .full,
                                    timeStyle: .short,
                                    locale: locale,
                                    timeZone: timeZone)
        print(result)
        XCTAssert(result == "dinsdag 22 november 1983 om 18:00")
    }
    
    func testFormattedDateAndTimeWithFormat() {
        let result = date.formatted(format: "EEEE d MMMM HH:mm",
                                    locale: locale,
                                    timeZone: timeZone)
        print(result)
        XCTAssert(result == "dinsdag 22 november 18:00")
    }
}
