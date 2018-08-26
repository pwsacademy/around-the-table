import BSON
import XCTest
@testable import AroundTheTable

class SponsorTests: XCTestCase {
    
    static var allTests: [(String, (SponsorTests) -> () throws -> Void)] {
        return [
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingCode", testDecodeMissingCode),
            ("testDecodeMissingName", testDecodeMissingName),
            ("testDecodeMissingDescription", testDecodeMissingDescription),
            ("testDecodeMissingPicture", testDecodeMissingPicture),
            ("testDecodeMissingLink", testDecodeMissingLink),
            ("testDecodeMissingWeight", testDecodeMissingWeight)
        ]
    }
    
    private let picture = URL(string: "http://some.picture/")!
    private let link = URL(string: "http://some.link/")!
    
    func testEncode() {
        let input = Sponsor(code: "abc", name: "ABC", description: "Lots of letters", picture: picture, link: link, weight: 2)
        let expected: Document = [
            "code": "abc",
            "name": "ABC",
            "description": "Lots of letters",
            "picture": picture,
            "link": link
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "code": "abc",
            "name": "ABC",
            "description": "Lots of letters",
            "picture": picture,
            "link": link,
            "weight": 2
        ]
        guard let result = try Sponsor(input) else {
            return XCTFail()
        }
        XCTAssert(result.code == "abc")
        XCTAssert(result.name == "ABC")
        XCTAssert(result.description == "Lots of letters")
        XCTAssert(result.picture == picture)
        XCTAssert(result.link == link)
        XCTAssert(result.weight == 2)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = "abc"
        let result = try Sponsor(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingCode() {
        let input: Document = [
            "name": "ABC",
            "description": "Lots of letters",
            "picture": picture,
            "link": link,
            "weight": 2
        ]
        XCTAssertThrowsError(try Sponsor(input))
    }
    
    func testDecodeMissingName() {
        let input: Document = [
            "code": "abc",
            "description": "Lots of letters",
            "picture": picture,
            "link": link,
            "weight": 2
        ]
        XCTAssertThrowsError(try Sponsor(input))
    }
    
    func testDecodeMissingDescription() {
        let input: Document = [
            "code": "abc",
            "name": "ABC",
            "picture": picture,
            "link": link,
            "weight": 2
        ]
        XCTAssertThrowsError(try Sponsor(input))
    }
    
    func testDecodeMissingPicture() {
        let input: Document = [
            "code": "abc",
            "name": "ABC",
            "description": "Lots of letters",
            "link": link,
            "weight": 2
        ]
        XCTAssertThrowsError(try Sponsor(input))
    }
    
    func testDecodeMissingLink() {
        let input: Document = [
            "code": "abc",
            "name": "ABC",
            "description": "Lots of letters",
            "picture": picture,
            "weight": 2
        ]
        XCTAssertThrowsError(try Sponsor(input))
    }
    
    func testDecodeMissingWeight() {
        let input: Document = [
            "code": "abc",
            "name": "ABC",
            "description": "Lots of letters",
            "picture": picture,
            "link": link
        ]
        XCTAssertThrowsError(try Sponsor(input))
    }
}
