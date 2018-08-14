import BSON
import XCTest
@testable import AroundTheTable

/**
 Run these tests against the **aroundthetable-test** database.
 Import it from **Tests/AroundTheTable/Fixtures/dump**.
 */
class UserRepositoryTests: XCTestCase {
    
    static var allTests: [(String, (UserRepositoryTests) -> () throws -> Void)] {
        return [
            ("testAddUser", testAddUser),
            ("testReadUser", testReadUser),
            ("testUpdateUser", testUpdateUser)
        ]
    }
    
    let persistence = try! Persistence()
    
    func testAddUser() throws {
        let david = User(name: "David")
        try persistence.add(david)
        XCTAssertNotNil(david.id)
        // Clean-up
        try persistence.users.remove(["name": "David"])
    }
    
    func testReadUser() throws {
        for id in [ObjectId("594d5ccd819a5360859a5360")!,
                   ObjectId("594d65bd819a5360869a5360")!,
                   ObjectId("594d5c76819a5360839a5360")!] {
            XCTAssertNotNil(try persistence.user(withID: id))
        }
    }
    
    func testUpdateUser() throws {
        guard let charlie = try persistence.user(withID: ObjectId("594d5c76819a5360839a5360")) else {
            return XCTFail()
        }
        XCTAssert(charlie.name == "Charlie")
        charlie.name = "Charlie Chaplin"
        try persistence.update(charlie)
        XCTAssert(try persistence.user(withID: ObjectId("594d5c76819a5360839a5360"))?.name == "Charlie Chaplin")
        // Clean-up
        charlie.name = "Charlie"
        try persistence.update(charlie)
    }
}
