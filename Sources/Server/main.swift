import CloudFoundryEnv
import Configuration
import Foundation
import HeliumLogger
import Kitura
import KituraSession
import KituraStencil
import LoggerAPI
import MongoKitten
import Stencil

HeliumLogger.use()

let configuration = ConfigurationManager().load(.environmentVariables)

private let router = Router()

private let stencil = Extension()
StencilFilters.register(on: stencil)
router.setDefault(templateEngine: StencilTemplateEngine(extension: stencil))

router.all(middleware: ForwardingMiddleware())

router.all("/public", middleware: StaticFileServer())

private let session = Session(secret: Secrets.sessionSecret, cookie: [.maxAge(14 * 24 * 3600.0)])

router.all("/authentication", middleware: [session])
private let credentials = configureAuthenticationRouter(using: router.route("/authentication"))

router.all("/web", middleware: session)
configureWebRouter(using: router.route("/web"), credentials)

router.get("/") {
    request, response, next in
    try response.redirect("/web/home")
    next()
}

/*
 Default error handler.
 Returns a 500 Internal Server Error for API requests.
 Renders an error page for web requests.
 */
router.error {
    request, response, next in
    if let error = response.error {
        let message: String
        switch error {
        case let error as Loggable:
            message = error.message
        default:
            message = error.localizedDescription
        }
        if !(error is Loggable) {
            // Loggable errors should have already been logged.
            Log.error(message)
        }
        if request.originalURL.contains("/api") {
            response.statusCode = .internalServerError
            response.send(message)
        } else {
            try response.render("\(Settings.locale)/error", context: request.userInfo.appending([
                "message": message
            ]))
        }
        response.error = nil
    }
    next()
}

Kitura.addHTTPServer(onPort: configuration.port, with: router)
Kitura.run()
