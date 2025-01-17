import BSON
import XCTest
@testable import AroundTheTable

/**
 Run these tests against the **aroundthetable-test** database.
 Import it from **Tests/AroundTheTable/Fixtures/dump**.
 */
class GameRepositoryTests: XCTestCase {
    
    static var allTests: [(String, (GameRepositoryTests) -> () throws -> Void)] {
        return [
            ("testQueryExact", testQueryExact),
            ("testQueryNotExact", testQueryNotExact),
            ("testQueryNoResults", testQueryNoResults),
            ("testGamesCached", testGamesCached),
            ("testGamesNew", testGamesNew),
            ("testGameCached", testGameCached),
            ("testGameNew", testGameNew)
        ]
    }
    
    let persistence = try! Persistence()
    
    func testQueryExact() {
        let resultsReceived = expectation(description: "results received")
        persistence.games(forQuery: "Small World", exactMatchesOnly: true) {
            ids in
            XCTAssert(ids == [40692])
            resultsReceived.fulfill()
        }
        waitForExpectations(timeout: 2) {
            error in
            XCTAssertNil(error)
        }
    }
    
    func testQueryNotExact() {
        let resultsReceived = expectation(description: "results received")
        persistence.games(forQuery: "Small World", exactMatchesOnly: false) {
            ids in
            XCTAssert(ids.count > 1)
            resultsReceived.fulfill()
        }
        waitForExpectations(timeout: 2) {
            error in
            XCTAssertNil(error)
        }
    }
    
    func testQueryNoResults() {
        let resultsReceived = expectation(description: "results received")
        persistence.games(forQuery: "definitely_no_results", exactMatchesOnly: false) {
            ids in
            XCTAssert(ids.isEmpty)
            resultsReceived.fulfill()
        }
        waitForExpectations(timeout: 2) {
            error in
            XCTAssertNil(error)
        }
    }
    
    func testGamesCached() throws {
        let ids = [1323, 27092, 192457]
        // The cache contains only these three games.
        XCTAssert(try persistence.games.count() == 3)
        XCTAssert(try persistence.games.count(["_id": ["$in": ids]]) == 3)
        // Now try to fetch them.
        let resultsReceived = expectation(description: "results received")
        try persistence.games(forIDs: ids) {
            games in
            XCTAssert(games.count == 3)
            resultsReceived.fulfill()
        }
        waitForExpectations(timeout: 2) {
            error in
            XCTAssertNil(error)
        }
        // There should be no additional games in the cache as a result of this operation.
        XCTAssert(try persistence.games.count() == 3)
    }
    
    func testGamesNew() throws {
        let id = 40692
        // The game shouldn't be in the cache.
        XCTAssertNil(try persistence.games.findOne(["_id": id]))
        // Now fetch it.
        let resultsReceived = expectation(description: "results received")
        try persistence.games(forIDs: [id]) {
            games in
            XCTAssert(games.count == 1)
            resultsReceived.fulfill()
        }
        waitForExpectations(timeout: 2) {
            error in
            XCTAssertNil(error)
        }
        // The game should now be in the cache.
        XCTAssertNotNil(try persistence.games.findOne(["_id": id]))
        // Clean-up
        try persistence.games.remove(["_id": id])
    }
    
    func testGameCached() throws {
        let id = 192457
        // The game should be in the cache.
        XCTAssertNotNil(try persistence.games.findOne(["_id": id]))
        XCTAssert(try persistence.games.count() == 3)
        // Now fetch it.
        let resultReceived = expectation(description: "result received")
        try persistence.game(forID: id) {
            game in
            XCTAssertNotNil(game)
            resultReceived.fulfill()
        }
        waitForExpectations(timeout: 2) {
            error in
            XCTAssertNil(error)
        }
        // There should be no additional games in the cache as a result of this operation.
        XCTAssert(try persistence.games.count() == 3)
    }
    
    func testGameNew() throws {
        let id = 40692
        // The game shouldn't be in the cache.
        XCTAssertNil(try persistence.games.findOne(["_id": id]))
        // Now fetch it.
        let resultReceived = expectation(description: "result received")
        try persistence.game(forID: id) {
            game in
            XCTAssertNotNil(game)
            resultReceived.fulfill()
        }
        waitForExpectations(timeout: 2) {
            error in
            XCTAssertNil(error)
        }
        // The game should now be in the cache.
        XCTAssertNotNil(try persistence.games.findOne(["_id": id]))
        // Clean-up
        try persistence.games.remove(["_id": id])
    }
}
