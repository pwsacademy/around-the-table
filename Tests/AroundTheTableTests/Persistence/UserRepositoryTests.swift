import BSON
import XCTest
@testable import AroundTheTable

/**
 Run these tests against the **att-test** database.
 Import it from **Tests/AroundTheTable/Fixtures/dump**.
 */
class UserRepositoryTests: XCTestCase {
    
    static var allTests: [(String, (UserRepositoryTests) -> () throws -> Void)] {
        return [
            ("testAddUser", testAddUser),
            ("testAddDuplicateUser", testAddDuplicateUser),
            ("testReadUser", testReadUser),
            ("testReadFacebookUser", testReadFacebookUser),
            ("testUpdateUser", testUpdateUser)
        ]
    }
    
    let persistence = try! Persistence()
    
    func testAddUser() throws {
        let david = User(facebookID: "4", name: "David")
        try persistence.add(david)
        XCTAssertNotNil(david.id)
        XCTAssertNotNil(try persistence.user(withFacebookID: "4"))
        // Clean-up
        try persistence.users.remove(["facebookID": "4"])
    }
    
    func testAddDuplicateUser() {
        let alsoAlice = User(facebookID: "1", name: "Also Alice")
        XCTAssertThrowsError(try persistence.add(alsoAlice))
    }
    
    func testReadUser() throws {
        for id in [ObjectId("594d5ccd819a5360859a5360")!,
                   ObjectId("594d65bd819a5360869a5360")!,
                   ObjectId("594d5c76819a5360839a5360")!] {
            XCTAssertNotNil(try persistence.user(withID: id))
        }
    }
    
    func testReadFacebookUser() throws {
        for id in ["1", "2", "3"] {
            XCTAssertNotNil(try persistence.user(withFacebookID: id))
        }
    }
    
    func testUpdateUser() throws {
        guard let charlie = try persistence.user(withFacebookID: "3") else {
            return XCTFail()
        }
        XCTAssert(charlie.name == "Charlie")
        charlie.name = "Charlie Chaplin"
        try persistence.update(charlie)
        XCTAssert(try persistence.user(withFacebookID: "3")?.name == "Charlie Chaplin")
        // Clean-up
        charlie.name = "Charlie"
        try persistence.update(charlie)
    }
}
