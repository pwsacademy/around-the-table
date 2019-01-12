import BSON
import XCTest
@testable import AroundTheTable

class ActivityTests: XCTestCase {
    
    static var allTests: [(String, (ActivityTests) -> () throws -> Void)] {
        return [
            ("testInitializationValues", testInitializationValues),
            ("testAvailableSeats", testAvailableSeats),
            ("testEncode", testEncode),
            ("testEncodeSkipsNilValues", testEncodeSkipsNilValues),
            ("testDecode", testDecode),
            ("testDecodeNotADocument", testDecodeNotADocument),
            ("testDecodeMissingID", testDecodeMissingID),
            ("testDecodeMissingCreationDate", testDecodeMissingCreationDate),
            ("testDecodeHostNotDenormalized", testDecodeHostNotDenormalized),
            ("testDecodeMissingName", testDecodeMissingName),
            ("testDecodeGameNotDenormalized", testDecodeGameNotDenormalized),
            ("testDecodeMissingPlayerCount", testDecodeMissingPlayerCount),
            ("testDecodeMissingPrereservedSeats", testDecodeMissingPrereservedSeats),
            ("testDecodeMissingDate", testDecodeMissingDate),
            ("testDecodeMissingDeadline", testDecodeMissingDeadline),
            ("testDecodeMissingLocation", testDecodeMissingLocation),
            ("testDecodeMissingInfo", testDecodeMissingInfo),
            ("testDecodeMissingIsCancelled", testDecodeMissingIsCancelled),
            ("testDecodeMissingRegistrations", testDecodeMissingRegistrations)
        ]
    }
    
    private let picture = URL(string: "https://cf.geekdo-images.com/original/img/ME73s_0dstlA4qLpLEBvPyvq8gE=/0x0/pic3090929.jpg")!
    private let thumbnail = URL(string: "https://cf.geekdo-images.com/thumb/img/7X5vG9KruQ9CmSMVZ3rmiSSqTCM=/fit-in/200x150/pic3090929.jpg")!
    private let now = Date()
    private let location = Location(coordinates: Coordinates(latitude: 50, longitude: 2),
                                    address: "Street 1", city: "City", country: "Country")
    private var host = User(id: 1, name: "Host")
    private var player = User(id: 2, name: "Player")
    
    private var game: Game {
        return Game(id: 1, name: "Game", names: ["Game"],
                    yearPublished: 2000,
                    playerCount: 2...4,
                    playingTime: 60...90,
                    picture: picture, thumbnail: thumbnail)
    }
    
    func testInitializationValues() {
        let activity = Activity(host: host,
                                name: "Game", game: game,
                                playerCount: 3...4, prereservedSeats: 2,
                                date: now, deadline: now,
                                location: location,
                                info: "Info")
        XCTAssertNil(activity.id)
        XCTAssertNil(activity.distance)
        XCTAssert(activity.picture == game.thumbnail)
        XCTAssertFalse(activity.isCancelled)
        XCTAssert(activity.registrations.isEmpty)
    }
    
    func testAvailableSeats() {
        let activity = Activity(host: host,
                                name: "Game", game: game,
                                playerCount: 3...4, prereservedSeats: 2,
                                date: now, deadline: now,
                                location: location,
                                info: "Info")
        var registration = Activity.Registration(player: player, seats: 1)
        registration.isApproved = true
        activity.registrations.append(registration)
        XCTAssert(activity.availableSeats == 1)
    }
    
    func testEncode() {
        let input = Activity(id: 1,
                             creationDate: now,
                             host: host,
                             name: "Game", game: game,
                             playerCount: 3...4, prereservedSeats: 2,
                             date: now, deadline: now,
                             location: location,
                             info: "Info")
        let registration = Activity.Registration(player: player, seats: 1)
        input.registrations.append(registration)
        let expected: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host.id,
            "name": "Game",
            "game": game.id,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "picture": game.thumbnail,
            "isCancelled": false,
            "registrations": [registration]
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testEncodeSkipsNilValues() {
        let input = Activity(id: 1,
                             creationDate: now,
                             host: host,
                             name: "Game", game: nil,
                             playerCount: 3...4, prereservedSeats: 2,
                             date: now, deadline: now,
                             location: location,
                             info: "Info")
        let expected: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host.id,
            "name": "Game",
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testDecode() throws {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "distance": 5,
            "info": "Info",
            "picture": picture,
            "isCancelled": false,
            "registrations": [
                [
                    "creationDate": now,
                    "player": player,
                    "seats": 1,
                    "isApproved": false,
                    "isCancelled": false
                ]
            ]
        ]
        guard let result = try Activity(input) else {
            return XCTFail()
        }
        XCTAssert(result.id == 1)
        assertDatesEqual(result.creationDate, now)
        XCTAssert(result.host == host)
        XCTAssert(result.name == "Game")
        XCTAssert(result.game == game)
        XCTAssert(result.playerCount == 3...4)
        XCTAssert(result.prereservedSeats == 2)
        assertDatesEqual(result.date, now)
        assertDatesEqual(result.deadline, now)
        XCTAssert(result.location == location)
        XCTAssert(result.distance == 5)
        XCTAssert(result.info == "Info")
        XCTAssert(result.picture == picture)
        XCTAssertFalse(result.isCancelled)
        XCTAssert(result.registrations.count == 1)
        assertDatesEqual(result.registrations[0].creationDate, now)
        XCTAssert(result.registrations[0].player == player)
        XCTAssert(result.registrations[0].seats == 1)
        XCTAssertFalse(result.registrations[0].isApproved)
        XCTAssertFalse(result.registrations[0].isCancelled)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = 1
        let result = try Activity(input)
        XCTAssertNil(result)
    }
    
    func testDecodeMissingID() {
        let input: Document = [
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingCreationDate() {
        let input: Document = [
            "_id": 1,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeHostNotDenormalized() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host.id,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingName() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeGameNotDenormalized() throws {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game.id,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        guard let result = try Activity(input) else {
            return XCTFail()
        }
        XCTAssertNil(result.game)
    }
    
    func testDecodeMissingPlayerCount() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingPrereservedSeats() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingDate() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingDeadline() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingLocation() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "info": "Info",
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingInfo() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "isCancelled": false,
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingIsCancelled() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "registrations": []
        ]
        XCTAssertThrowsError(try Activity(input))
    }
    
    func testDecodeMissingRegistrations() {
        let input: Document = [
            "_id": 1,
            "creationDate": now,
            "host": host,
            "name": "Game",
            "game": game,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
        ]
        XCTAssertThrowsError(try Activity(input))
    }
}
