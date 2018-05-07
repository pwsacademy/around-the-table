import Foundation
import Configuration
import CloudFoundryEnv
import Credentials
import CredentialsFacebook
import Kitura
import KituraSession
import LoggerAPI

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
    let facebook = CredentialsFacebook(clientId: Settings.facebook.appID,
                                       clientSecret: Secrets.facebookAppSecret,
                                       callbackUrl: callbackURL,
                                       options: ["fields": "name,picture.type(large)", "scope": ["public_profile"]])
    credentials.register(plugin: facebook)
    credentials.options["failureRedirect"] = "/authentication/welcome"
    
    /*
     Authentication starts on the welcome page.
     This page records the `returnTo` address so the user can be redirected back to where he was.
     A new `returnTo` address is then set up to redirect the user to the sign-up page after authenticating with Facebook.
     */
    router.get("/welcome", middleware: BaseContextMiddleware())
    router.get("/welcome") {
        request, response, next in
        guard let session = request.session else {
            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
        }
        if let redirect = request.queryParameters["redirect"] {
            // The user clicked on a link to sign in.
            session["originalReturnTo"] = redirect
        } else if var returnAddress = Credentials.getRedirectingReturnTo(for: request) {
            // The user was redirected by the Credentials middleware.
            if let proto = request.headers["X-Forwarded-Proto"], proto == "https", !returnAddress.hasPrefix("https://") {
                // Bluemix terminates SSL at the proxy level.
                // This means we have to change the URL to https if the original request used https.
                returnAddress = returnAddress.replacingOccurrences(of: "http://", with: "https://")
            }
            session["originalReturnTo"] = returnAddress
        }
        Credentials.setRedirectingReturnTo("/authentication/signup", for: request)
        try response.render("\(Settings.locale)/welcome", context: request.userInfo)
        next()
    }
    
    router.get("/signin", handler: credentials.authenticate(credentialsType: facebook.name))
    router.get("/signin/callback", handler: credentials.authenticate(credentialsType: facebook.name))
    
    /*
     Presents the user with a sign-up page.
     */
    router.get("/signup", middleware: [credentials, BaseContextMiddleware()])
    router.get("/signup") {
        request, response, next in
        guard let session = request.session else {
            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
        }
        guard let profile = request.userProfile else {
            try logAndThrow(ServerError.missingMiddleware(type: Credentials.self))
        }
        if let user = try UserRepository().user(withID: profile.id) {
            // Update the user's name and picture.
            user.name = profile.displayName
            if let picture = profile.photos?.first?.value {
                user.picture = URL(string: picture)
            }
            try UserRepository().update(user)
            // Skip sign-up if the user has already signed up.
            if let returnAddress = session["originalReturnTo"] as? String, !returnAddress.contains("authentication") {
                session.remove(key: "originalReturnTo")
                try response.redirect(returnAddress)
            } else {
                try response.redirect("/web/home")
            }
        } else {
            try response.render("\(Settings.locale)/signup", context: request.userInfo)
        }
        next()
    }
    
    /*
     Adds the user to the database.
     */
    router.post("/signup", middleware: [credentials, BodyParser()])
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
        if let returnAddress = session["originalReturnTo"] as? String, !returnAddress.contains("authentication") {
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
        try response.redirect("/web/home")
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
//            dummy = User(id: id, name: id, picture: nil)
//            try UserRepository().add(dummy!)
//        }
//        session["userProfile"] = [
//            "id": dummy!.id,
//            "displayName": dummy!.name,
//            "provider": "dummy"
//        ]
//        try response.redirect("/web/home")
//        next()
//    }
    
    return credentials
}
