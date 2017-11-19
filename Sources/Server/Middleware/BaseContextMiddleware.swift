import Credentials
import Kitura

/*
 Sets the rendering context necessary for the `base.stencil` template.
 Loads location information from the user's settings.
 Also loads related settings like the list of supported countries and the Google API key.
 */
struct BaseContextMiddleware: RouterMiddleware {
    
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // Start with default values.
        var userInfo: [String: Any] = [:]
        var coordinatesInfo: [String: Any] = [
            "latitude": Settings.defaultCoordinates.latitude,
            "longitude": Settings.defaultCoordinates.longitude,
            "actual": false
        ]
        // If a user is signed in, load that user's values instead.
        if let userID = request.userProfile?.id,
           let user = try UserRepository().user(withID: userID) {
            let unreadMessageCount = try MessageRepository().unreadMessageCount(for: user)
            userInfo = [
                "id": user.id,
                "name": user.name,
                "picture": user.picture?.absoluteString ?? Settings.defaultProfilePicture,
                "unreadMessageCount": unreadMessageCount
            ]
            if let location = user.location {
                coordinatesInfo = [
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "actual": true
                ]
            }
        }
        request.userInfo.append([
            "global": [
                "user": userInfo,
                "coordinates": coordinatesInfo,
                "countries": "[\(Settings.countries.map { "\"\($0)\"" }.joined(separator: ", "))]", // Builds a JSON array.
                "googleAPIKey": Secrets.googleAPIKey
            ]
        ])
        next()
    }
}
