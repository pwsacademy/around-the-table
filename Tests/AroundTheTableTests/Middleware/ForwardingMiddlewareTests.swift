import Kitura
import SwiftyRequest
import XCTest
@testable import AroundTheTable

class ForwardingMiddlewareTests: XCTestCase {
    
    static var allTests: [(String, (ForwardingMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testForward", testForward),
            ("testNoForwardWithoutDomain", testNoForwardWithoutDomain),
            ("testHealthException", testHealthException)
        ]
    }
    
    func testForward() {
        let router = Router()
        router.all(middleware: ForwardingMiddleware(domain: "github.com"))
        
        Kitura.addHTTPServer(onPort: 8081, with: router)
        Kitura.start()
        
        let requestReceived = expectation(description: "request received")
        let request = RestRequest(url: "http://localhost:8081/")
        request.responseVoid {
            response in
            XCTAssert(response.response?.url == URL(string: "https://github.com/"))
            requestReceived.fulfill()
        }
        
        waitForExpectations(timeout: 5) {
            error in
            Kitura.stop()
            XCTAssertNil(error)
        }
    }
    
    func testNoForwardWithoutDomain() {
        let router = Router()
        router.all(middleware: ForwardingMiddleware(domain: nil))
        router.get {
            request, response, next in
            response.send("Hello")
            next()
        }
        
        Kitura.addHTTPServer(onPort: 8081, with: router)
        Kitura.start()
        
        let requestReceived = expectation(description: "request received")
        let request = RestRequest(url: "http://localhost:8081/")
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
    
    func testHealthException() {
        let router = Router()
        router.all(middleware: ForwardingMiddleware(domain: "github.com"))
        router.get("/health") {
            request, response, next in
            response.send("Hello")
            next()
        }
        
        Kitura.addHTTPServer(onPort: 8081, with: router)
        Kitura.start()
        
        let requestReceived = expectation(description: "request received")
        let request = RestRequest(url: "http://localhost:8081/health")
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
    
    // Note: SSL forwarding is untested here as we don't use HTTPS on localhost.
}
