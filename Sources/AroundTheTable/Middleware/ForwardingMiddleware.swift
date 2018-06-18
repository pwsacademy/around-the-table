import Kitura

/**
 Forwards all requests to a specific domain if one is configured.
 This middleware also enforces HTTPS when running in the cloud.
 */
struct ForwardingMiddleware: RouterMiddleware {
    
    /// The domain to forward to.
    let domain: String?
    
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        if let domain = domain, request.hostname != domain {
            try response.redirect("https://\(domain)/")
        } else if let proto = request.headers["X-Forwarded-Proto"], proto == "http" {
            // IBM Cloud terminates SSL at the proxy level.
            // This means we have to check the `X-Forwarded-Proto` header, not the URL, to find out if the original request used HTTP.
            try response.redirect(request.originalURL.replacingOccurrences(of: "http://", with: "https://"))
        } else {
            next()
        }
    }
}
