import Foundation
import Configuration
import CloudFoundryEnv
import Credentials
import CredentialsFacebook
import Kitura
import KituraSession
import LoggerAPI
import SwiftyJSON

/*
 Handles the authentication flow based on Facebook Web Login.
 Configures and returns a Credentials middleware.
 */
func configureAuthenticationRouter(using router: Router) -> Credentials {
    
    let credentials = Credentials()
    let callbackURL: String
    if let customDomainName = Settings.customDomainName, !configuration.isLocal {
        callbackURL = "https://\(customDomainName)/authentication/signin/callback"
    } else {
        callbackURL = "\(configuration.url)/authentication/signin/callback"
    }
    let facebook = CredentialsFacebook(clientId: Secrets.facebookAppID,
                                       clientSecret: Secrets.facebookAppSecret,
                                       callbackUrl: callbackURL,
                                       options: ["fields": "name,picture.type(large)"])
    credentials.register(plugin: facebook)
    credentials.options["failureRedirect"] = "/authentication/welcome"
    
    /*
     Authentication starts on the welcome page.
     This page records the `returnTo` address so the user can be redirected back to where he was.
     A new `returnTo` address is then set up to redirect the user to the sign-up page after authenticating with Facebook.
     */
    router.get("/welcome") {
        request, response, next in
        guard let session = request.session else {
            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
        }
        if var returnAddress = Credentials.getRedirectingReturnTo(for: request) {
            if let proto = request.headers["X-Forwarded-Proto"], proto == "https", !returnAddress.hasPrefix("https://") {
                // Bluemix terminates SSL at the proxy level.
                // This means we have to change the URL to https if the original request used https.
                returnAddress = returnAddress.replacingOccurrences(of: "http://", with: "https://")
            }
            session["originalReturnTo"] = JSON(returnAddress)
        }
        Credentials.setRedirectingReturnTo("/authentication/signup", for: request)
        try response.render("\(Settings.locale)/welcome", context: [:])
        next()
    }
    
    router.get("/signin", allowPartialMatch: false, middleware: SaveLocationMiddleware())
    router.get("/signin", handler: credentials.authenticate(credentialsType: facebook.name))
    router.get("/signin/callback", handler: credentials.authenticate(credentialsType: facebook.name))
    
    /*
     Presents the user with a sign-up page.
     */
    router.all("/signup", middleware: credentials)
    router.get("/signup") {
        request, response, next in
        guard let session = request.session else {
            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
        }
        guard let id = request.userProfile?.id else {
            try logAndThrow(ServerError.missingMiddleware(type: Credentials.self))
        }
        if try UserRepository().user(withID: id) != nil {
            // Skip sign-up if the user has already signed up.
            if let returnAddress = session["originalReturnTo"].string, !returnAddress.contains("authentication") {
                session.remove(key: "originalReturnTo")
                try response.redirect(returnAddress)
            } else {
                try response.redirect("/web/home")
            }
        } else {
            try response.render("\(Settings.locale)/signup", context: [:])
        }
        next()
    }
    
    /*
     Adds the user to the database.
     */
    router.post("/signup", middleware: BodyParser())
    router.post("/signup") {
        request, response, next in
        guard let body = request.body?.asURLEncoded,
              body["agree"] == "on" else {
            try logAndThrow(ServerError.invalidRequest)
        }
        guard let session = request.session else {
            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
        }
        guard let profile = request.userProfile else {
            try logAndThrow(ServerError.missingMiddleware(type: Credentials.self))
        }
        let picture = profile.photos?.first?.value
        let user = User(id: profile.id,
                        name: profile.displayName,
                        picture: picture != nil ? URL(string: picture!) : nil)
        try UserRepository().add(user)
        // Redirect the user back to where he/she was (or to the home page).
        if let returnAddress = session["originalReturnTo"].string, !returnAddress.contains("authentication") {
            session.remove(key: "originalReturnTo")
            try response.redirect(returnAddress)
        } else {
            try response.redirect("/web/home")
        }
        next()
    }
    
    router.get("/signout") {
        request, response, next in
        guard let session = request.session else {
            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
        }
        credentials.logOut(request: request)
        session.destroy {
            error in
            if let error = error {
                Log.error(error.description)
            }
        }
        try response.redirect("/authentication/welcome")
        next()
    }
    
    /*
     Dummy user support for testing without Facebook.
     */
//    router.get("/dummy/:id") {
//        request, response, next in
//        guard let id = request.parameters["id"] else {
//            try logAndThrow(ServerError.invalidRequest)
//        }
//        guard let session = request.session else {
//            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
//        }
//        var dummy = try UserRepository().user(withID: id)
//        if dummy == nil {
//            dummy = User(id: id, name: id, dateOfBirth: Date(), picture: nil)
//            try UserRepository().add(dummy!)
//        }
//        session["userProfile"] = JSON([
//            "id": dummy!.id,
//            "displayName": dummy!.name,
//            "provider": "dummy"
//        ])
//        next()
//    }
    
    return credentials
}
