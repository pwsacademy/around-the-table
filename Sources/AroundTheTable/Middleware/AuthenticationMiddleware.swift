import Credentials
import Kitura

/**
 Verifies that the authenticated user is an existing user.
 If not, the new user is redirected to the sign-up page.
 Requires a preceding `Credentials` middleware.
 */
struct AuthenticationMiddleware: RouterMiddleware {
    
    let persistence: Persistence
    
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard let id = request.userProfile?.id else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        if try persistence.user(withID: id) == nil {
            try response.redirect("/authentication/signup")
        } else {
            next()
        }
    }
}
