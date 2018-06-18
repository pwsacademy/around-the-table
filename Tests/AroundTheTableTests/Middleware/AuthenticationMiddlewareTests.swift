import Kitura
import KituraSession
import SwiftyRequest
import XCTest
@testable import AroundTheTable

class AuthenticationMiddlewareTests: XCTestCase {
    
    /*
     One test is commented out due to https://bugs.swift.org/browse/SR-7861.
     */
    static var allTests: [(String, (AuthenticationMiddlewareTests) -> () throws -> Void)] {
        return [
//            ("testForwardToSignUp", testForwardToSignUp),
            ("testNoForwardForExistingUser", testNoForwardForExistingUser)
        ]
    }
    
    private struct DummyUserMiddleware: RouterMiddleware {
        
        let id: String
        
        func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
            guard let session = request.session else {
                throw log(ServerError.missingMiddleware(type: Session.self))
            }
            session["userProfile"] = [
                "id": id,
                "displayName": "Dummy",
                "provider": "Dummy"
            ]
            next()
        }
    }
    
    func testForwardToSignUp() throws {
        let persistence = try Persistence()
        let router = Router()
        router.get("test", middleware: [
            Session(secret: "secret"),
            DummyUserMiddleware(id: "unknown"),
            AuthenticationMiddleware(persistence: persistence)
        ])
        router.get("test") {
            request, response, next in
            response.send("Hello")
            next()
        }
        
        Kitura.addHTTPServer(onPort: 8081, with: router)
        Kitura.start()
        
        let requestReceived = expectation(description: "request received")
        let request = RestRequest(url: "http://localhost:8081/test")
        request.responseVoid {
            response in
            XCTAssert(response.response?.url == URL(string: "http://localhost:8081/authentication/signup"))
            requestReceived.fulfill()
        }
        
        waitForExpectations(timeout: 5) {
            error in
            Kitura.stop()
            XCTAssertNil(error)
        }
    }
    
    func testNoForwardForExistingUser() throws {
        let persistence = try Persistence()
        let router = Router()
        router.get("test", middleware: [
            Session(secret: "secret"),
            DummyUserMiddleware(id: "1"),
            AuthenticationMiddleware(persistence: persistence)
        ])
        router.get("test") {
            request, response, next in
            response.send("Hello")
            next()
        }
        
        Kitura.addHTTPServer(onPort: 8081, with: router)
        Kitura.start()
        
        let requestReceived = expectation(description: "request received")
        let request = RestRequest(url: "http://localhost:8081/test")
        request.responseString {
            response in
            XCTAssert(response.result == .success("Hello"))
            requestReceived.fulfill()
        }
        
        waitForExpectations(timeout: 5) {
            error in
            Kitura.stop()
            XCTAssertNil(error)
        }
    }
}
