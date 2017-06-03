import Credentials
import Kitura

/*
 Sets the rendering context necessary for the `base.stencil` template.
 This context is stored in the `request.userInfo` dictionary.
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
                "name": user.name,
                "picture": user.picture?.absoluteString ?? Settings.defaultProfilePicture
            ],
            "unreadMessageCount": unreadMessageCount
        ])
        next()
    }
}
