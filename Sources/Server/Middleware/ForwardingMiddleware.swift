import Kitura

/*
 Forwards all requests to a custom domain if one is configured.
 Enforces the use of SSL.
 Does nothing when running on localhost.
 */
struct ForwardingMiddleware: RouterMiddleware {
    
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard request.hostname != "localhost" else {
            return next()
        }
        if let customDomainName = Settings.customDomainName, request.hostname != customDomainName {
            try response.redirect("https://\(customDomainName)/")
        } else if let proto = request.headers["X-Forwarded-Proto"], proto == "http" {
            // Bluemix terminates SSL at the proxy level.
            // This means we have to check the `X-Forwarded-Proto` header, not the URL, to find out if https was used.
            try response.redirect(request.originalURL.replacingOccurrences(of: "http://", with: "https://"))
        }
        next()
    }
}
