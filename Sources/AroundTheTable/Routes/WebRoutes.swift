import Credentials
import Kitura

extension Routes {
    
    /**
     Registers the web routes on the given router.
     */
    func configureWeb(using router: Router, credentials: Credentials) {
        router.get("home", handler: home)
        router.get("faq", handler: faq)
    }
    
    /**
     Shows the home page.
     */
    private func home(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("home", with: base, forKey: "base")
        next()
    }
    
    /**
     Shows the FAQ.
     */
    private func faq(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("faq", with: base, forKey: "base")
        next()
    }
}
