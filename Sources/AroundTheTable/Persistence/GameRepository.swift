import Foundation
import LoggerAPI
import SwiftyRequest

/**
 Persistence methods related to games.
 */
extension Persistence {
    
    /**
     Queries BoardGameGeek for games that match a query.
     
     - Returns: IDs of games that match the query.
     */
    func games(forQuery query: String, exactMatchesOnly: Bool, callback: @escaping ([Int]) -> Void) {
        let request = RestRequest(url: "https://boardgamegeek.com/xmlapi2/search")
        request.responseData(queryItems: [
            URLQueryItem(name: "type", value: "boardgame"),
            URLQueryItem(name: "exact", value: exactMatchesOnly ? "1" : "0"),
            URLQueryItem(name: "query", value: query)
        ]) { response in
            guard case .success(let data) = response.result,
                  let xml = try? XMLDocument(data: data, options: []) else {
                Log.warning("No valid XML data returned for query \(query).")
                return callback([])
            }
            do {
                guard let totalString = try xml.nodes(forXPath: "/items/@total").first?.stringValue,
                      let total = Int(totalString), total > 0 else {
                    return callback([])
                }
                let results: [Int] = try xml.nodes(forXPath: "/items/item/@id").compactMap {
                    guard let id = $0.stringValue else {
                        return nil
                    }
                    return Int(id)
                }
                callback(results)
            } catch {
                Log.warning("Failed to parse XML for query \(query).")
                callback([])
            }
        }
    }
    
    /**
     Looks up game data on BoardGameGeek.
     
     Performs an aggregate request and offers better performance compared to multiple `game(forID:)` calls.
     
     - Returns: Games for the given IDs.
                Cached results are returned when available.
                Games that have missing or invalid data are excluded.
     */
    func games(forIDs ids: [Int], callback: @escaping ([Game]) -> Void) throws {
        guard !ids.isEmpty else {
            return callback([])
        }
        // First check which games are in the cache.
        let cachedIDs = try ids.filter { try games.count(["_id": $0], limitedTo: 1) == 1 }
        let cachedGames = try games.find(["_id": ["$in": cachedIDs]]).compactMap(Game.init)
        // Then fetch the remaining ones.
        let newIDs = ids.filter { !cachedIDs.contains($0) }
        let joinedIDs = newIDs.map { String($0) }.joined(separator: ",")
        let request = RestRequest(url: "https://boardgamegeek.com/xmlapi2/thing")
        request.responseData(queryItems: [URLQueryItem(name: "id", value: joinedIDs)]) {
            response in
            guard case .success(let data) = response.result,
                  let xml = try? XMLDocument(data: data, options: []) else {
                Log.warning("No valid XML data returned for IDs \(joinedIDs).")
                return callback(cachedGames)
            }
            do {
                // Note that the try? in the following statement is important.
                // We don't want to throw an error if a node has missing or invalid data.
                // Instead, we simply exlude it from the results.
                let results = try xml.nodes(forXPath: "/items/item").compactMap { try? Game(xml: $0) }
                // Cache the new games.
                try self.games.insert(contentsOf: results.map { $0.document })
                callback(cachedGames + results)
            } catch {
                Log.warning("Failed to parse XML for IDs \(joinedIDs).")
                callback(cachedGames)
            }
        }
    }
    
    /**
     Looks up game data on BoardGameGeek.
     
     - Returns: The game with the given ID.
                A cached result is returned when available.
                Returns `nil` if there is no game with this ID or if the game has missing or invalid data.
     */
    func game(forID id: Int, callback: @escaping (Game?) -> Void) throws {
        // First check if the game is in the cache.
        if let game = try games.findOne(["_id": id]).map(Game.init) {
            return callback(game)
        }
        // If not, fetch it.
        let request = RestRequest(url: "https://boardgamegeek.com/xmlapi2/thing")
        request.responseData(queryItems: [URLQueryItem(name: "id", value: "\(id)")]) {
            response in
            guard case .success(let data) = response.result,
                  let xml = try? XMLDocument(data: data, options: []) else {
                Log.warning("No valid XML data returned for ID \(id).")
                return callback(nil)
            }
            do {
                // Note that the try? in the following statement is important.
                // We don't want to throw an error if the node has missing or invalid data.
                // Instead, we simply return nil.
                guard let node = try xml.nodes(forXPath: "/items/item[@id='\(id)']").first,
                      let game = try? Game(xml: node) else {
                    return callback(nil)
                }
                // Cache the new game.
                try self.games.insert(game.document)
                callback(game)
            } catch {
                Log.warning("Failed to parse XML for ID \(id).")
                callback(nil)
            }
        }
    }
    
    /**
     Checks if BGG has a medium size (_md) picture for this game.
     If so, the game's picture will be replaced with this medium size one.
     */
    func checkMediumPicture(for game: Game) {
        // Do nothing if the game doesn't have a picture or if it already has a medium size one.
        guard let url = game.picture?.absoluteString,
              !url.contains("_md") else {
            return
        }
        let urlComponents = url.components(separatedBy: "/")
        guard urlComponents.count > 1,
              let file = urlComponents.last,
              let period = file.index(of: ".") else {
            Log.warning("Invalid picture URL for #\(game.id).")
            return
        }
        let fileName = file[..<period]
        let fileExtension = file[period...]
        let newURL = "https://cf.geekdo-images.com/images/\(fileName)_md\(fileExtension)"
        let request = RestRequest(method: .head, url: newURL)
        request.responseVoid {
            response in
            guard response.response?.statusCode == 200 else {
                Log.info("No medium size picture available for #\(game.id)")
                return
            }
            do {
                try self.games.update(["_id": game.id], to: ["$set": ["picture": newURL]])
            } catch {
                Log.warning("Failed to update picture URL for #\(game.id)")
            }
        }
    }
}
