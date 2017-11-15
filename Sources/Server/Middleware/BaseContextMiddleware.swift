import Credentials
import Kitura

/*
 Sets the rendering context necessary for the `base.stencil` template.
 Loads location information from the user's settings.
 Also loads related settings like the list of supported countries and the Google API key.
 Requires a preceding AuthenticationMiddleware.
 */
struct BaseContextMiddleware: RouterMiddleware {
    
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard let userID = request.userProfile?.id else {
            try logAndThrow(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let user = try UserRepository().user(withID: userID) else {
            try logAndThrow(ServerError.missingMiddleware(type: AuthenticationMiddleware.self))
        }
        let unreadMessageCount = try MessageRepository().unreadMessageCount(for: user)
        request.userInfo.append([
            "user": [
                "id": user.id,
                "name": user.name,
                "picture": user.picture?.absoluteString ?? Settings.defaultProfilePicture
            ],
            "unreadMessageCount": unreadMessageCount
        ])
        if let location = user.location {
            request.userInfo["coordinates"] = [
                "latitude": location.latitude,
                "longitude": location.longitude,
                "actual": true
            ]
        } else {
            request.userInfo["coordinates"] = [
                "latitude": Settings.defaultCoordinates.latitude,
                "longitude": Settings.defaultCoordinates.longitude,
                "actual": false
            ]
        }
        request.userInfo["countries"] = "[\(Settings.countries.map { "\"\($0)\"" }.joined(separator: ", "))]" // Builds a JSON array.
        request.userInfo["googleAPIKey"] = Secrets.googleAPIKey
        next()
    }
}
