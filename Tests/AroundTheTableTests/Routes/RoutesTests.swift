import Kitura
import SwiftyRequest
import XCTest
@testable import AroundTheTable

class RoutesTests: XCTestCase {
    
    static var allTests: [(String, (RoutesTests) -> () throws -> Void)] {
        return [
            ("testStaticFileServer", testStaticFileServer),
            ("testErrorHandlerForAPIRoutes", testErrorHandlerForAPIRoutes),
            ("testErrorHandlerForWebRoutes", testErrorHandlerForWebRoutes)
        ]
    }
    
    func testStaticFileServer() throws {
        let persistence = try Persistence()
        let router = Router()
        Routes(persistence: persistence).configure(using: router)
        
        Kitura.addHTTPServer(onPort: 8081, with: router)
        Kitura.start()
        
        let requestReceived = expectation(description: "request received")
        let request = RestRequest(url: "http://localhost:8081/public/img/logo.png")
        request.responseVoid {
            response in
            XCTAssert(response.response?.statusCode == 200)
            requestReceived.fulfill()
        }
        
        waitForExpectations(timeout: 5) {
            error in
            Kitura.stop()
            XCTAssertNil(error)
        }
    }
    
    func testErrorHandlerForAPIRoutes() throws {
        let persistence = try Persistence()
        let router = Router()
        // This route must be added first, otherwise it will come after the error handler.
        router.get("/api/something-bad") {
            request, response, next in
            throw ServerError.invalidState
        }
        Routes(persistence: persistence).configure(using: router)
        
        Kitura.addHTTPServer(onPort: 8081, with: router)
        Kitura.start()
        
        let requestReceived = expectation(description: "request received")
        let request = RestRequest(url: "http://localhost:8081/api/something-bad")
        request.responseVoid {
            response in
            XCTAssert(response.response?.statusCode == 500)
            requestReceived.fulfill()
        }
        
        waitForExpectations(timeout: 5) {
            error in
            Kitura.stop()
            XCTAssertNil(error)
        }
    }
    
    func testErrorHandlerForWebRoutes() throws {
        let persistence = try Persistence()
        let router = Router()
        // This route must be added first, otherwise it will come after the error handler.
        router.get("/web/something-bad") {
            request, response, next in
            throw ServerError.invalidState
        }
        Routes(persistence: persistence).configure(using: router)
        
        Kitura.addHTTPServer(onPort: 8081, with: router)
        Kitura.start()
        
        let requestReceived = expectation(description: "request received")
        let request = RestRequest(url: "http://localhost:8081/web/something-bad")
        request.responseString {
            response in
            // Should display an error page and not return an error code.
            XCTAssert(response.response?.statusCode == 200)
            requestReceived.fulfill()
        }
        
        waitForExpectations(timeout: 5) {
            error in
            Kitura.stop()
            XCTAssertNil(error)
        }
    }
}
