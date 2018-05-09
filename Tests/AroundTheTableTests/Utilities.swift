import Foundation
import XCTest

/**
 Asserts that two dates are equal.
 
 This function allows for sub-millisecond differences that result from floating-point rounding errors.
 */
func assertDatesEqual(_ date1: Date, _ date2: Date) {
    XCTAssert(abs(date1.timeIntervalSince(date2)) < 0.001)
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
