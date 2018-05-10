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
    
    private let id = try! ObjectId("594d5bef819a5360829a5360")
    private let host = User(id: "1", name: "Host")
    private let player = User(id: "2", name: "Player")
    private let game = Game(id: 1, name: "Game", names: ["Game"],
                            yearPublished: 2000,
                            playerCount: 2...4,
                            playingTime: 60...90,
                            picture: nil, thumbnail: nil)
    private let now = Date()
    private let location = Location(coordinates: Coordinates(latitude: 50, longitude: 2),
                                    address: "Street 1", city: "City", country: "Country")
    
    func testInitializationValues() {
        let activity = Activity(host: host,
                                name: "Game", game: game,
                                playerCount: 3...4, prereservedSeats: 2,
                                date: now, deadline: now,
                                location: location,
                                info: "Info")
        XCTAssertNil(activity.distance)
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
        let input = Activity(host: host,
                             name: "Game", game: game,
                             playerCount: 3...4, prereservedSeats: 2,
                             date: now, deadline: now,
                             location: location,
                             info: "Info")
        input.id = id
        let registration = Activity.Registration(player: player, seats: 1)
        input.registrations.append(registration)
        let expected: Document = [
            "_id": id,
            "creationDate": input.creationDate,
            "host": host.id,
            "name": "Game",
            "game": game.id,
            "playerCount": 3...4,
            "prereservedSeats": 2,
            "date": now,
            "deadline": now,
            "location": location,
            "info": "Info",
            "isCancelled": false,
            "registrations": [ registration ]
        ]
        XCTAssert(input.typeIdentifier == expected.typeIdentifier)
        XCTAssert(input.document == expected)
    }
    
    func testEncodeSkipsNilValues() {
        let input = Activity(host: host,
                             name: "Game", game: nil,
                             playerCount: 3...4, prereservedSeats: 2,
                             date: now, deadline: now,
                             location: location,
                             info: "Info")
        input.id = id
        let expected: Document = [
            "_id": id,
            "creationDate": input.creationDate,
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
            "_id": id,
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
        XCTAssert(result.id == id)
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
        XCTAssertFalse(result.isCancelled)
        XCTAssert(result.registrations.count == 1)
        assertDatesEqual(result.registrations[0].creationDate, now)
        XCTAssert(result.registrations[0].player == player)
        XCTAssert(result.registrations[0].seats == 1)
        XCTAssertFalse(result.registrations[0].isApproved)
        XCTAssertFalse(result.registrations[0].isCancelled)
    }
    
    func testDecodeNotADocument() throws {
        let input: Primitive = id
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
            "_id": id,
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
