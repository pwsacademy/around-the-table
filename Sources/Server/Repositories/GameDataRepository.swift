import Foundation
import KituraNet
import LoggerAPI
import MongoKitten

struct GameDataRepository {
    
    /*
     Looks up game data on BoardGameGeek.
     Returns a locally cached result if available.
     Returns nil if there was no result or if the result has missing or invalid data.
     */
    func gameData(forID id: Int) throws -> GameData? {
        if let game = try collection(.gameData).findOne(["_id": id]) {
            return try GameData(bson: game)
        }
        var result: GameData?
        var error: Swift.Error?
        let request = HTTP.request("https://boardgamegeek.com/xmlapi2/thing?id=\(id)") {
            response in
            guard let response = response, response.statusCode == .OK else {
                error = log(BoardGameGeekError.missingOrInvalidData)
                return
            }
            var data = Data()
            do {
                try response.readAllData(into: &data)
            } catch let dataError {
                error = dataError
                return
            }
            guard let xml = try? XMLDocument(data: data, options: []) else {
                error = log(BoardGameGeekError.missingOrInvalidData)
                return
            }
            do {
                guard let gameXML = try xml.nodes(forXPath: "/items/item[@id='\(id)']").first else {
                    error = log(BoardGameGeekError.missingOrInvalidData)
                    return
                }
                result = try GameData(xml: gameXML)
            } catch let xmlError {
                error = xmlError
                return
            }
        }
        request.end()
        guard error == nil else {
            throw error!
        }
        if let result = result {
            try collection(.gameData).insert(result.toBSON())
        }
        return result
    }
    
    /*
     Looks up game data on BoardGameGeek.
     Returns locally cached results when available.
     Results returned by BoardGameGeek that have missing or invalid data are excluded from the result.
     Performs an aggregate request and offers better performance compared to multiple `gameData(forID:)` calls.
     */
    func gameData(forIDs ids: [Int]) throws -> [GameData] {
        guard !ids.isEmpty else {
            return []
        }
        let cachedIDs = try ids.filter { try collection(.gameData).count(["_id": $0], limitedTo: 1) == 1 }
        let cachedGames = try collection(.gameData).find(["_id": ["$in": cachedIDs]]).map { try GameData(bson: $0) }
        let newIDs = ids.filter { !cachedIDs.contains($0) }
        let joinedIDs = newIDs.map { String($0) }.joined(separator: ",")
        var results: [GameData]?
        var error: Swift.Error?
        let request = HTTP.request("https://boardgamegeek.com/xmlapi2/thing?id=\(joinedIDs)") {
            response in
            guard let response = response, response.statusCode == .OK else {
                error = log(BoardGameGeekError.missingOrInvalidData)
                return
            }
            var data = Data()
            do {
                try response.readAllData(into: &data)
            } catch let dataError {
                error = dataError
                return
            }
            guard let xml = try? XMLDocument(data: data, options: []) else {
                error = log(BoardGameGeekError.missingOrInvalidData)
                return
            }
            do {
                results = try xml.nodes(forXPath: "/items/item").flatMap { try? GameData(xml: $0) }
            } catch let xmlError {
                error = xmlError
                return
            }
        }
        request.end()
        guard error == nil else {
            throw error!
        }
        try collection(.gameData).insert(contentsOf: results!.map { $0.toBSON() })
        return cachedGames + results!
    }
    
    /*
     Queries BoardGameGeek then looks up game data using `gameData(forIDs:)`.
     */
    func searchResults(forQuery query: String, exactMatchesOnly exact: Bool = true) throws -> [GameData] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            try logAndThrow(ServerError.percentEncodingFailed)
        }
        let url = "https://boardgamegeek.com/xmlapi2/search?type=boardgame\(exact ? "&exact=1" : "")&query=\(encodedQuery)"
        var results: [Int]?
        var error: Swift.Error?
        let request = HTTP.request(url) {
            response in
            guard let response = response, response.statusCode == .OK else {
                error = log(BoardGameGeekError.missingOrInvalidData)
                return
            }
            var data = Data()
            do {
                try response.readAllData(into: &data)
            } catch let dataError {
                error = dataError
                return
            }
            guard let xml = try? XMLDocument(data: data, options: []) else {
                error = log(BoardGameGeekError.missingOrInvalidData)
                return
            }
            do {
                guard let totalString = try xml.nodes(forXPath: "/items/@total").first?.stringValue,
                      let total = Int(totalString), total > 0 else {
                    results = []
                    return
                }
                results = try xml.nodes(forXPath: "/items/item/@id").map {
                    guard let idString = $0.stringValue,
                          let id = Int(idString) else {
                        try logAndThrow(BoardGameGeekError.missingOrInvalidData)
                    }
                    return id
                }
            } catch let xmlError {
                error = xmlError
                return
            }
        }
        request.end()
        guard error == nil else {
            throw error!
        }
        return try gameData(forIDs: results!.withoutDuplicates())
    }
    
    private let session = URLSession(configuration: .default)
    
    /*
     Checks if BGG has a medium size (_md) version of this picture.
     If so, replaces the picture with it.
     */
    func checkMediumPicture(forID id: Int) throws {
        guard let gameData = try gameData(forID: id) else {
            try logAndThrow(ServerError.invalidState)
        }
        guard let url = gameData.picture?.absoluteString,
              !url.contains("_md") else {
            return
        }
        let urlComponents = url.components(separatedBy: "/")
        guard urlComponents.count > 1,
              let file = urlComponents.last,
              let period = file.index(of: ".") else {
            Log.warning("Invalid medium size picture URL for #\(id)")
            return
        }
        let fileName = file[..<period]
        let fileExtension = file[period...]
        guard let newURL = URL(string: "https://cf.geekdo-images.com/images/\(fileName)_md\(fileExtension)") else {
            Log.warning("Invalid medium size picture URL for #\(id)")
            return
        }
        var request = URLRequest(url: newURL)
        request.httpMethod = "HEAD"
        let task = session.dataTask(with: request) {
            (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                Log.info("No medium size picture available for #\(id)")
                return
            }
            do {
                try collection(.gameData).update(["_id": id], to: ["$set": ["picture": newURL.absoluteString]])
            } catch {
                Log.warning("Failed to update picture URL for #\(id)")
            }
        }
        task.resume()
    }
}
