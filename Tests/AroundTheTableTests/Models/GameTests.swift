import BSON
import Foundation
import XCTest
@testable import AroundTheTable

class GameTests: XCTestCase {
    
    /*
     Some tests are commented out due to https://bugs.swift.org/browse/SR-4628.
     This should be fixed in Swift 4.2.
     */
    static var allTests: [(String, (GameTests) -> () throws -> Void)] {
        return [
            ("testParseXML", testParseXML),
//            ("testParseXMLNoID", testParseXMLNoID),
//            ("testParseXMLNoName", testParseXMLNoName),
//            ("testParseXMLZeroYear", testParseXMLZeroYear),
//            ("testParseXMLNoMinPlayers", testParseXMLNoMinPlayers),
//            ("testParseXMLNoMaxPlayers", testParseXMLNoMaxPlayers),
//            ("testParseXMLZeroPlayerCount", testParseXMLZeroPlayerCount),
//            ("testParseXMLZeroMinPlayers", testParseXMLZeroMinPlayers),
//            ("testParseXMLZeroMaxPlayers", testParseXMLZeroMaxPlayers),
//            ("testParseXMLInvertedPlayerCount", testParseXMLInvertedPlayerCount),
//            ("testParseXMLNoMinPlaytime", testParseXMLNoMinPlaytime),
//            ("testParseXMLNoMaxPlaytime", testParseXMLNoMaxPlaytime),
//            ("testParseXMLZeroPlaytime", testParseXMLZeroPlaytime),
//            ("testParseXMLZeroMinPlaytime", testParseXMLZeroMinPlaytime),
//            ("testParseXMLZeroMaxPlaytime", testParseXMLZeroMaxPlaytime),
//            ("testParseXMLInvertedPlaytime", testParseXMLInvertedPlaytime),
//            ("testParseXMLNoImage", testParseXMLNoImage),
//            ("testParseXMLNoThumbnail", testParseXMLNoThumbnail),
            ("testEncode", testEncode),
            ("testEncodeSkipsNilValues", testEncodeSkipsNilValues),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingID", testDecodeMissingID),
            ("testDecodeMissingCreationDate", testDecodeMissingCreationDate),
            ("testDecodeMissingName", testDecodeMissingName),
            ("testDecodeMissingNames", testDecodeMissingNames),
            ("testDecodeMissingYear", testDecodeMissingID),
            ("testDecodeMissingPlayerCount", testDecodeMissingPlayerCount),
            ("testDecodeMissingPlayingTime", testDecodeMissingPlayingTime)
        ]
    }
    
    private let now = Date()
    private let picture = URL(string: "https://cf.geekdo-images.com/original/img/ME73s_0dstlA4qLpLEBvPyvq8gE=/0x0/pic3090929.jpg")!
    private let thumbnail = URL(string: "https://cf.geekdo-images.com/thumb/img/7X5vG9KruQ9CmSMVZ3rmiSSqTCM=/fit-in/200x150/pic3090929.jpg")!
    
    /* XML */
    
    func testParseXML() throws {
        guard let data = loadFixture(file: "xml/valid.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssert(result.id == 192457)
        XCTAssert(result.name == "Cry Havoc")
        XCTAssert(result.names == ["Cry Havoc"])
        XCTAssert(result.yearPublished == 2016)
        XCTAssert(result.playerCount == 2...4)
        XCTAssert(result.playingTime == 60...120)
        XCTAssert(result.picture == picture)
        XCTAssert(result.thumbnail == thumbnail)
    }
    
    func testParseXMLNoID() throws {
        guard let data = loadFixture(file: "xml/no-id.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLNoName() throws {
        guard let data = loadFixture(file: "xml/no-name.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLZeroYear() throws {
        guard let data = loadFixture(file: "xml/zero-year.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLNoMinPlayers() throws {
        guard let data = loadFixture(file: "xml/no-minplayers.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLNoMaxPlayers() throws {
        guard let data = loadFixture(file: "xml/no-maxplayers.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLZeroPlayerCount() throws {
        guard let data = loadFixture(file: "xml/zero-playercount.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLZeroMinPlayers() throws {
        guard let data = loadFixture(file: "xml/zero-minplayers.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssert(result.playerCount == 4...4)
    }
    
    func testParseXMLZeroMaxPlayers() throws {
        guard let data = loadFixture(file: "xml/zero-maxplayers.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssert(result.playerCount == 2...2)
    }
    
    func testParseXMLInvertedPlayerCount() throws {
        guard let data = loadFixture(file: "xml/inverted-playercount.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssert(result.playerCount == 2...4)
    }
    
    func testParseXMLNoMinPlaytime() throws {
        guard let data = loadFixture(file: "xml/no-minplaytime.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLNoMaxPlaytime() throws {
        guard let data = loadFixture(file: "xml/no-maxplaytime.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLZeroPlaytime() throws {
        guard let data = loadFixture(file: "xml/zero-playtime.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        XCTAssertThrowsError(try Game(xml: node))
    }
    
    func testParseXMLZeroMinPlaytime() throws {
        guard let data = loadFixture(file: "xml/zero-minplaytime.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssert(result.playingTime == 120...120)
    }
    
    func testParseXMLZeroMaxPlaytime() throws {
        guard let data = loadFixture(file: "xml/zero-maxplaytime.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssert(result.playingTime == 60...60)
    }
    
    func testParseXMLInvertedPlaytime() throws {
        guard let data = loadFixture(file: "xml/inverted-playtime.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssert(result.playingTime == 60...120)
    }
    
    func testParseXMLNoImage() throws {
        guard let data = loadFixture(file: "xml/no-image.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssertNil(result.picture)
    }
    
    func testParseXMLNoThumbnail() throws {
        guard let data = loadFixture(file: "xml/no-thumbnail.xml") else {
            return XCTFail()
        }
        let xml = try XMLDocument(data: data, options: [])
        guard let node = try xml.nodes(forXPath: "/items/item").first else {
            return XCTFail()
        }
        let result = try Game(xml: node)
        XCTAssertNil(result.thumbnail)
    }
    
    /* BSON */
    
    func testEncode() {
        let input = Game(id: 1,
                         name: "game", names: ["game", "spiel"],
                         yearPublished: 2000,
                         playerCount: 2...4,
                         playingTime: 45...60,
                         picture: picture, thumbnail: thumbnail)
        let expected: Document = [
            "_id": 1,
            "creationDate": input.creationDate,
            "name": "game",
            "names": ["game", "spiel"],
            "yearPublished": 2000,
            "playerCount": 2...4,
            "playingTime": 45...60,
            "picture": picture,
            "thumbnail": thumbnail
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testEncodeSkipsNilValues() {
        let input = Game(id: 1,
                         name: "game", names: ["game", "spiel"],
                         yearPublished: 2000,
                         playerCount: 2...4,
                         playingTime: 45...60,
                         picture: nil, thumbnail: nil)
        let expected: Document = [
            "_id": 1,
            "creationDate": input.creationDate,
            "name": "game",
            "names": ["game", "spiel"],
            "yearPublished": 2000,
            "playerCount": 2...4,
            "playingTime": 45...60
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "name": "game",
            "names": ["game", "spiel"],
            "yearPublished": 2000,
            "playerCount": 2...4,
            "playingTime": 45...60,
            "picture": picture,
            "thumbnail": thumbnail
        ]
        guard let result = try Game(input) else {
            return XCTFail()
        }
        XCTAssert(result.id == 1)
        assertDatesEqual(result.creationDate, now)
        XCTAssert(result.name == "game")
        XCTAssert(result.names == ["game", "spiel"])
        XCTAssert(result.yearPublished == 2000)
        XCTAssert(result.playerCount == 2...4)
        XCTAssert(result.playingTime == 45...60)
        XCTAssert(result.picture == picture)
        XCTAssert(result.thumbnail == thumbnail)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = 1
        let result = try Game(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingID() {
        let input: Document = [
            "creationDate": now,
            "name": "game",
            "names": ["game", "spiel"],
            "yearPublished": 2000,
            "playerCount": 2...4,
            "playingTime": 45...60
        ]
        XCTAssertThrowsError(try Game(input))
    }
    
    func testDecodeMissingCreationDate() {
        let input: Document = [
            "_id": 1,
            "name": "game",
            "names": ["game", "spiel"],
            "yearPublished": 2000,
            "playerCount": 2...4,
            "playingTime": 45...60
        ]
        XCTAssertThrowsError(try Game(input))
    }
    
    func testDecodeMissingName() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "names": ["game", "spiel"],
            "yearPublished": 2000,
            "playerCount": 2...4,
            "playingTime": 45...60
        ]
        XCTAssertThrowsError(try Game(input))
    }
    
    func testDecodeMissingNames() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "name": "game",
            "yearPublished": 2000,
            "playerCount": 2...4,
            "playingTime": 45...60
        ]
        XCTAssertThrowsError(try Game(input))
    }
    
    func testDecodeMissingYear() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "name": "game",
            "names": ["game", "spiel"],
            "playerCount": 2...4,
            "playingTime": 45...60
        ]
        XCTAssertThrowsError(try Game(input))
    }
    
    func testDecodeMissingPlayerCount() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "name": "game",
            "names": ["game", "spiel"],
            "yearPublished": 2000,
            "playingTime": 45...60
        ]
        XCTAssertThrowsError(try Game(input))
    }
    
    func testDecodeMissingPlayingTime() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "name": "game",
            "names": ["game", "spiel"],
            "yearPublished": 2000,
            "playerCount": 2...4
        ]
        XCTAssertThrowsError(try Game(input))
    }
}
