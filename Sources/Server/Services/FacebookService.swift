import Foundation
import LoggerAPI

struct FacebookService {
    
    private let accessToken: String
    private let session = URLSession(configuration: .default)
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func accounce(_ game: Game) throws {
        // Skip this all together if no Facebook group is configured or if running on localhost.
        guard let groupID = Settings.facebookGroupID, !configuration.isLocal else {
            return
        }
        guard let id = game.id else {
            try logAndThrow(ServerError.unpersistedEntity)
        }
        // Build form data.
        let message = Strings.facebookAnnouncement(for: game).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let linkURL: String
        if let customDomainName = Settings.customDomainName {
            linkURL = "https://\(customDomainName)"
        } else {
            linkURL = "\(configuration.url)"
        }
        let link = "\(linkURL)/web/game/\(id)".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let data = "message=\(message)&link=\(link)".data(using: .utf8)!
        // Send request asynchronously.
        let requestURL = URL(string: "https://graph.facebook.com/v2.3/\(groupID)/feed?access_token=\(accessToken)")!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = session.uploadTask(with: request, from: data) {
            data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                Log.error("Facebook game annoucement failed: no response.")
                return
            }
            guard httpResponse.statusCode == 200 else {
                Log.error("Facebook game annoucement failed: invalid response.")
                Log.error(httpResponse.debugDescription)
                return
            }
        }
        task.resume()
    }
}
