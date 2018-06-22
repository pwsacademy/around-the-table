import SwiftyRequest
import XCTest
@testable import AroundTheTable

class CloudObjectStorageTests: XCTestCase {
    
    static var allTests: [(String, (CloudObjectStorageTests) -> () throws -> Void)] {
        return [
            ("testGetToken", testGetToken),
            ("testGetData", testGetData),
            ("testStoreAndDelete", testStoreAndDelete)
        ]
    }
    
    func testGetToken() {
        guard CloudObjectStorage.isConfigured else {
            print("Skipping CloudObjectStorageTests.testGetToken.")
            return
        }
        let tokenReceived = expectation(description: "token received")
        let cos = CloudObjectStorage()
        XCTAssertFalse(cos.hasValidToken)
        cos.getToken {
            token in
            XCTAssert(cos.hasValidToken)
            tokenReceived.fulfill()
        }
        waitForExpectations(timeout: 5) {
            error in
            XCTAssertNil(error)
        }
    }
    
    private let url = URL(string: "https://raw.githubusercontent.com/svanimpe/around-the-table/master/public/img/favicon.png")!
    
    func testGetData() {
        let dataReceived = expectation(description: "data received")
        let cos = CloudObjectStorage()
        cos.getData(from: url) {
            data in
            XCTAssert(data.count == 63030)
            dataReceived.fulfill()
        }
        waitForExpectations(timeout: 5) {
            error in
            XCTAssertNil(error)
        }
    }
    
    func testStoreAndDelete() {
        guard CloudObjectStorage.isConfigured else {
            print("Skipping CloudObjectStorageTests.testStoreAndDelete.")
            return
        }
        let objectStored = expectation(description: "object stored")
        let cos = CloudObjectStorage()
        cos.storeImage(at: url, as: "test/favicon.png") {
            let request = RestRequest(method: .head, url: "\(Settings.cloudObjectStorage.bucketURL!)/test/favicon.png")
            request.responseVoid {
                response in
                XCTAssert(response.response?.statusCode == 200)
                objectStored.fulfill()
            }
        }
        waitForExpectations(timeout: 5) {
            error in
            XCTAssertNil(error)
        }
        
        let objectDeleted = expectation(description: "object deleted")
        cos.delete(object: "test/favicon.png") {
            objectDeleted.fulfill()
        }
        waitForExpectations(timeout: 5) {
            error in
            XCTAssertNil(error)
        }
    }
}
