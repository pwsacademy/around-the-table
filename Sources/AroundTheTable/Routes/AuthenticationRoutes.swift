import Credentials
import Foundation
import Kitura
import KituraSession
import LoggerAPI

extension Routes {
    
    /**
     Registers the authentication routes on the given router.
     */
    func configureAuthentication(using router: Router, credentials: Credentials) {
        router.get("welcome", handler: welcome)
        router.get("signin", handler: credentials.authenticate(credentialsType: "Facebook"))
        router.get("signin/callback", handler: credentials.authenticate(credentialsType: "Facebook"))
        router.get("signup", middleware: credentials)
        router.get("signup", handler: showSignUp)
        router.post("signup", middleware: [credentials, BodyParser()])
        router.post("signup", handler: processSignUp)
        router.get("signout", handler: signOut)
        if Settings.areDummiesEnabled {
            router.get("dummy/:id", handler: dummy)
        }
    }
    
    /**
     Authentication starts on the welcome page.
     This page records the `returnTo` address so the user can be redirected back to where he was.
     A new `returnTo` address is then set up to redirect the user to the sign-up page after authenticating with Facebook.
     */
    private func welcome(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        if let redirect = request.queryParameters["redirect"] {
            // The user clicked on a link to sign in.
            session["originalReturnTo"] = redirect
        } else if var returnAddress = Credentials.getRedirectingReturnTo(for: request) {
            // The user was redirected by the Credentials middleware.
            if let proto = request.headers["X-Forwarded-Proto"], proto == "https", !returnAddress.hasPrefix("https://") {
                // IBM Cloud terminates SSL at the proxy level.
                // This means we have to change the URL to HTTPS if the original request used HTTPS.
                returnAddress = returnAddress.replacingOccurrences(of: "http://", with: "https://")
            }
            session["originalReturnTo"] = returnAddress
        }
        Credentials.setRedirectingReturnTo("/authentication/signup", for: request)
        let base = try baseViewModel(for: request)
        try response.render("welcome", with: base, forKey: "base")
        next()
    }
    
    /**
     Presents the user with a sign-up form.
     */
    private func showSignUp(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        guard let profile = request.userProfile else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        if let user = try persistence.user(withID: profile.id) {
            // Update the user's data.
            user.name = profile.displayName
            let picture = profile.photos?.first?.value
            user.picture = picture != nil ? URL(string: picture!) : nil
            user.lastSignIn = Date()
            try persistence.update(user)
            // Skip the sign-up page because the user has already signed up.
            if let returnAddress = session["originalReturnTo"] as? String, !returnAddress.contains("authentication") {
                session.remove(key: "originalReturnTo")
                try response.redirect(returnAddress)
            } else {
                try response.redirect("/web/home")
            }
        } else {
            let base = try baseViewModel(for: request)
            try response.render("signup", with: base, forKey: "base")
            next()
        }
    }
    
    /**
     Processes the sign-up form and adds the user to the database.
     */
    private func processSignUp(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let body = request.body?.asURLEncoded,
              body["agree"] == "on" else {
            response.status(.badRequest)
            return next()
        }
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        guard let profile = request.userProfile else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        let picture = profile.photos?.first?.value
        let user = User(id: profile.id,
                        name: profile.displayName,
                        picture: picture != nil ? URL(string: picture!) : nil)
        try persistence.add(user)
        // Redirect the user back to where he/she was (or to the home page).
        if let returnAddress = session["originalReturnTo"] as? String, !returnAddress.contains("authentication") {
            session.remove(key: "originalReturnTo")
            try response.redirect(returnAddress)
        } else {
            try response.redirect("/web/home")
        }
    }
    
    /**
     Ends the user's session.
     */
    private func signOut(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        Credentials().logOut(request: request)
        session.destroy {
            error in
            if let error = error {
                Log.error(error.description)
            }
        }
        try response.redirect("/web/home")
    }
    
    /**
     Signs in with a dummy account.
     This should only be enabled in development.
     */
    private func dummy(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let id = request.parameters["id"] else {
            response.status(.badRequest)
            return next()
        }
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        var dummy = try persistence.user(withID: id)
        if dummy == nil {
            dummy = User(id: id, name: "Dummy \(id)")
            try persistence.add(dummy!)
        }
        session["userProfile"] = [
            "id": dummy!.id,
            "displayName": dummy!.name,
            "provider": "Dummy"
        ]
        try response.redirect("/web/home")
    }
}
