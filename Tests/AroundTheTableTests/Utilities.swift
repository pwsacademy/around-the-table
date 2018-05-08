import Foundation
import XCTest

/**
 Asserts that two dates are equal.
 
 This function allows for sub-millisecond differences that result from floating-point rounding errors.
 */
func assertDatesEqual(_ date1: Date, _ date2: Date) {
    XCTAssert(abs(date1.timeIntervalSince(date2)) < 0.001)
}
