import BSON
import XCTest
@testable import AroundTheTable

/**
 Run these tests against the **aroundthetable-test** database.
 Import it from **Tests/AroundTheTable/Fixtures/dump**.
 */
class SponsorRepositoryTests: XCTestCase {
    
    static var allTests: [(String, (SponsorRepositoryTests) -> () throws -> Void)] {
        return [
            ("testAddSponsor", testAddSponsor),
            ("testAddExistingSponsor", testAddExistingSponsor),
            ("testRemoveSponsor", testRemoveSponsor),
            ("testUpdateSponsor", testUpdateSponsor),
            ("testSponsorWithCode", testSponsorWithCode),
            ("testRandomSponsor", testRandomSponsor),
            ("testAllSponsors", testAllSponsors)
        ]
    }
    
    let persistence = try! Persistence()

    func testAddSponsor() throws {
        let third = Sponsor(code: "third",
                            name: "Sponsor C",
                            description: "Our third sponsor",
                            picture: URL(string: "http://some.picture/")!,
                            link: URL(string: "http://some.link/")!,
                            weight: 3)
        XCTAssert(try persistence.sponsors.count(["code": "third"]) == 0)
        try persistence.add(third)
        XCTAssert(try persistence.sponsors.count(["code": "third"]) == 3)
        // Clean-up
        try persistence.sponsors.remove(["code": "third"])
    }
    
    func testAddExistingSponsor() throws {
        guard let first = try persistence.sponsor(withCode: "first") else {
            return XCTFail()
        }
        XCTAssertThrowsError(try persistence.add(first))
    }
    
    func testRemoveSponsor() throws {
        guard let first = try persistence.sponsor(withCode: "first") else {
            return XCTFail()
        }
        try persistence.remove(first)
        XCTAssertNil(try persistence.sponsors.findOne(["code": "first"]))
        // Clean-up
        try persistence.add(first)
    }
    
    func testUpdateSponsor() throws {
        guard let first = try persistence.sponsor(withCode: "first") else {
            return XCTFail()
        }
        XCTAssert(first.description == "Our first sponsor")
        first.description = "Our awesome first sponsor"
        try persistence.update(first)
        XCTAssertEqual("Our awesome first sponsor", try persistence.sponsor(withCode: "first")?.description)
        // Clean-up
        first.description = "Our first sponsor"
        try persistence.update(first)
    }
    
    func testSponsorWithCode() throws {
        guard let first = try persistence.sponsor(withCode: "first") else {
            return XCTFail()
        }
        XCTAssert(first.name == "Sponsor A")
    }
    
    /*
     Caution: there is randomness involved in this test.
     Occasional failures are to be excepted and do not indicate an error.
     */
    func testRandomSponsor() throws {
        var counts = [
            "first": 0,
            "second": 0
        ]
        for _ in 1...1000 {
            guard let sponsor = try persistence.randomSponsor() else {
                return XCTFail()
            }
            counts[sponsor.code]! += 1
        }
        XCTAssert(233...433 ~= counts["first"]!) // Should be around 333.
        XCTAssert(566...766 ~= counts["second"]!) // Should be around 666.
    }
    
    func testAllSponsors() throws {
        let results = try persistence.allSponsors()
        XCTAssert(results.map { $0.code } == [
            "second",
            "first"
        ])
    }
}
