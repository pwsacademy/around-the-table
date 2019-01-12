import BSON
import XCTest
@testable import AroundTheTable

/**
 Run these tests against the **aroundthetable-test** database.
 Import it from **Tests/AroundTheTable/Fixtures/dump**.
 */
class CredentialsRepositoryTests: XCTestCase {
    
    static var allTests: [(String, (CredentialsRepositoryTests) -> () throws -> Void)] {
        return [
            ("testAddEmailCredential", testAddEmailCredential),
            ("testAddEmailCredentialUpdatesExistingCredential", testAddEmailCredentialUpdatesExistingCredential),
            ("testAddConflictingEmailCredential", testAddConflictingEmailCredential),
            ("testAddFacebookCredential", testAddFacebookCredential),
            ("testAddFacebookCredentialUpdatesExistingCredential", testAddFacebookCredentialUpdatesExistingCredential),
            ("testAddConflictingFacebookCredential", testAddConflictingFacebookCredential),
            ("testUserWithEmail", testUserWithEmail),
            ("testUserWithEmailNotFound", testUserWithEmailNotFound),
            ("testUserWithEmailAndPassword", testUserWithEmailAndPassword),
            ("testUserWithEmailAndPasswordNotFound", testUserWithEmailAndPasswordNotFound),
            ("testUserWithEmailAndInvalidPassword", testUserWithEmailAndInvalidPassword),
            ("testUserWithFacebookID", testUserWithFacebookID),
            ("testUserWithFacebookIDNotFound", testUserWithFacebookIDNotFound)
        ]
    }
    
    let persistence = try! Persistence()
    
    func testAddEmailCredential() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        try persistence.addEmailCredential(for: bob, email: "bob@dylan.com", password: "supersecret")
        XCTAssertNotNil(try persistence.userWith(email: "bob@dylan.com", password: "supersecret"))
        // Clean-up
        try persistence.credentials.remove(["_id": bob.id])
    }
    
    func testAddEmailCredentialUpdatesExistingCredential() throws {
        guard let alice = try persistence.userWith(email: "alice@wonderland.com", password: "supersecret") else {
            return XCTFail()
        }
        try persistence.addEmailCredential(for: alice, email: "alice@kansas.us", password: "notanymore")
        XCTAssertEqual(alice, try persistence.userWith(email: "alice@kansas.us", password: "notanymore"))
        // Clean-up
        try persistence.addEmailCredential(for: alice, email: "alice@wonderland.com", password: "supersecret")
    }
    
    func testAddConflictingEmailCredential() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        XCTAssertThrowsError(try persistence.addEmailCredential(for: bob, email: "alice@wonderland.com", password: "supersecret"))
    }
    
    func testAddFacebookCredential() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        try persistence.addFacebookCredential(for: bob, facebookID: "2")
        XCTAssertNotNil(try persistence.userWith(facebookID: "2"))
        // Clean-up
        try persistence.credentials.remove(["_id": bob.id])
    }
    
    func testAddFacebookCredentialUpdatesExistingCredential() throws {
        guard let alice = try persistence.userWith(facebookID: "1") else {
            return XCTFail()
        }
        try persistence.addFacebookCredential(for: alice, facebookID: "100")
        XCTAssertEqual(alice, try persistence.userWith(facebookID: "100"))
        // Clean-up
        try persistence.addFacebookCredential(for: alice, facebookID: "1")
    }
    
    func testAddConflictingFacebookCredential() throws {
        guard let bob = try persistence.user(withID: 2) else {
            return XCTFail()
        }
        XCTAssertThrowsError(try persistence.addFacebookCredential(for: bob, facebookID: "1"))
    }
    
    func testUserWithEmail() throws {
        guard let alice = try persistence.user(withID: 1) else {
            return XCTFail()
        }
        XCTAssertEqual(alice, try persistence.userWith(email: "alice@wonderland.com"))
    }
    
    func testUserWithEmailNotFound() throws {
        XCTAssertNil(try persistence.userWith(email: "bob@wonderland.com"))
    }
    
    func testUserWithEmailAndPassword() throws {
        guard let alice = try persistence.user(withID: 1) else {
            return XCTFail()
        }
        XCTAssertEqual(alice, try persistence.userWith(email: "alice@wonderland.com", password: "supersecret"))
    }
    
    func testUserWithEmailAndPasswordNotFound() throws {
        XCTAssertNil(try persistence.userWith(email: "bob@wonderland.com", password: "supersecret"))
    }
    
    func testUserWithEmailAndInvalidPassword() throws {
        XCTAssertNil(try persistence.userWith(email: "alice@wonderland.com", password: "incorrect"))
    }
    
    func testUserWithFacebookID() throws {
        guard let alice = try persistence.user(withID: 1) else {
            return XCTFail()
        }
        XCTAssertEqual(alice, try persistence.userWith(facebookID: "1"))
    }
    
    func testUserWithFacebookIDNotFound() throws {
        XCTAssertNil(try persistence.userWith(facebookID: "-1"))
    }
}
