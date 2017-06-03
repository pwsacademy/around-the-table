import Credentials
import Kitura

/*
 Verifies that the authenticated user is an existing user.
 If not, the new user is redirected to the sign-up page.
 Requires a preceding Credentials middleware.
 */
struct AuthenticationMiddleware: RouterMiddleware {

    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard let userID = request.userProfile?.id else {
            try logAndThrow(ServerError.missingMiddleware(type: Credentials.self))
        }
        if try UserRepository().user(withID: userID) == nil {
            try response.redirect("/authentication/signup")
        }
        next()
    }
}
