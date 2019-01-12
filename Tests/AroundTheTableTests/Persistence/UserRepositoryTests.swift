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
        for id in 1...3 {
            XCTAssertNotNil(try persistence.user(withID: id))
        }
    }
    
    func testUpdateUser() throws {
        guard let charlie = try persistence.user(withID: 3) else {
            return XCTFail()
        }
        XCTAssert(charlie.name == "Charlie")
        charlie.name = "Charlie Chaplin"
        try persistence.update(charlie)
        XCTAssert(try persistence.user(withID: 3)?.name == "Charlie Chaplin")
        // Clean-up
        charlie.name = "Charlie"
        try persistence.update(charlie)
    }
}
