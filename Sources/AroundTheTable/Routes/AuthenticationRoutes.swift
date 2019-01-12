import Credentials
import Foundation
import Kitura
import KituraSession
import LoggerAPI

extension Routes {
    
    /**
     Registers the authentication routes on the given router.
     */
    func configureAuthenticationRoutes(using router: Router, credentials: Credentials) {
        router.get("welcome", handler: showWelcome)
        router.post("welcome", handler: signInWithEmail)
        router.get("signup", handler: showSignUpWithEmail)
        router.post("signup", handler: signUpWithEmail)
        router.get("facebook", handler: credentials.authenticate(credentialsType: "Facebook"))
        router.get("facebook/callback", handler: credentials.authenticate(credentialsType: "Facebook"))
        router.get("facebook/signup", middleware: credentials)
        router.get("facebook/signup", handler: showSignUpWithFacebook)
        router.post("facebook/signup", middleware: credentials)
        router.post("facebook/signup", handler: signUpWithFacebook)
        router.get("signout", handler: signOut)
    }
    
    /**
     Authentication starts on the welcome page.
     This page records the `returnTo` address so the user can be redirected back to where he was.
     A new `returnTo` address is then set up to redirect the user to the sign-up page after authenticating with Facebook.
     */
    private func showWelcome(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
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
        // After authenticating with Facebook, the user needs to sign up to create an account.
        // This redirect is only used by the Facebook plug-in after a user has authenticated.
        // This is different from the Credentials middleware's failure redirect,
        // which redirects an unauthenticated user to the welcome page.
        Credentials.setRedirectingReturnTo("/authentication/facebook/signup", for: request)
        let base = try baseViewModel(for: request)
        try response.render("welcome", with: WelcomeViewModel(base: base, error: false))
        next()
    }
    
    /**
     Processes the sign-in form submitted on the welcome page.
     */
    private func signInWithEmail(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        guard let form = try? request.read(as: SignInForm.self) else {
            response.status(.badRequest)
            return next()
        }
        // Check the email address and password.
        guard let user = try persistence.userWith(email: form.email, password: form.password) else {
            let base = try baseViewModel(for: request)
            try response.render("welcome", with: WelcomeViewModel(base: base, error: true))
            return next()
        }
        // Add a userProfile key to the session.
        // The Credentials middleware will use this to set the RouterRequest.userProfile property.
        // This effectively signs the user in.
        session["userProfile"] = [
            "id": form.email,
            "displayName": user.name,
            "provider": "Email"
        ]
        user.lastSignIn = Date()
        try persistence.update(user)
        // Redirect the user back to where he was (or to the home page).
        if let returnAddress = session["originalReturnTo"] as? String, !returnAddress.contains("authentication") {
            session.remove(key: "originalReturnTo")
            try response.redirect(returnAddress)
        } else {
            try response.redirect("/web/home")
        }
    }
    
    /**
     Shows the sign-up page where the user can create an account with email credentials.
     */
    private func showSignUpWithEmail(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("signup-email", with: base, forKey: "base")
        next()
    }
    
    /**
     Processes the sign-up form and creates an account with email credentials.
     */
    private func signUpWithEmail(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        guard let form = try? request.read(as: SignUpForm.self) else {
            response.status(.badRequest)
            return next()
        }
        // Check that the email address isn't already used.
        guard try persistence.userWith(email: form.email) == nil else {
            let base = try baseViewModel(for: request)
            try response.render("signup-email", with: EmailSignUpViewModel(base: base,
                                                                           name: form.name,
                                                                           email: form.email,
                                                                           error: true))
            return next()
        }
        let user = User(name: form.name)
        try persistence.add(user)
        try persistence.addEmailCredential(for: user, email: form.email, password: form.password)
        // Add a userProfile key to the session.
        // The Credentials middleware will use this to set the RouterRequest.userProfile property.
        // This effectively signs the user in.
        session["userProfile"] = [
            "id": form.email,
            "displayName": form.name,
            "provider": "Email"
        ]
        // Redirect the user back to where he was (or to the home page).
        if let returnAddress = session["originalReturnTo"] as? String, !returnAddress.contains("authentication") {
            session.remove(key: "originalReturnTo")
            try response.redirect(returnAddress)
        } else {
            try response.redirect("/web/home")
        }
        next()
    }
    
    /**
     After authenticating with Facebook, the user needs to sign up to create an account.
     */
    private func showSignUpWithFacebook(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        guard let profile = request.userProfile else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        // Verify the user went through Facebook sign-in.
        // A user could sign in with email credentials and then try to execute this route, which isn't intended.
        guard profile.provider == "Facebook" else {
            response.status(.badRequest)
            return next()
        }
        if let user = try persistence.userWith(facebookID: profile.id) {
            // For an existing user, update the user's data.
            user.name = profile.displayName
            var pictureChanged = false
            if let picture = profile.photos?.first?.value {
                user.picture = URL(string: picture)
                pictureChanged = true
            }
            user.lastSignIn = Date()
            try persistence.update(user)
            if pictureChanged {
                try storePicture(for: user)
            }
            // Skip the sign-up page and redirect the user to where he was (or to the home page).
            if let returnAddress = session["originalReturnTo"] as? String, !returnAddress.contains("authentication") {
                session.remove(key: "originalReturnTo")
                try response.redirect(returnAddress)
            } else {
                try response.redirect("/web/home")
            }
        } else {
            // For a new user, send the user to the sign-up page.
            let base = try baseViewModel(for: request)
            try response.render("signup-facebook", with: FacebookSignUpViewModel(base: base,
                                                                                 name: profile.displayName,
                                                                                 picture: profile.photos?.first?.value ?? Settings.defaultProfilePicture))
            next()
        }
    }
    
    /**
     Processes the sign-up form and creates an account with Facebook credentials for the user.
     */
    private func signUpWithFacebook(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let session = request.session else {
            throw log(ServerError.missingMiddleware(type: Session.self))
        }
        guard let profile = request.userProfile else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        // Verify the user went through Facebook sign-in.
        // A user could sign in with email credentials and then try to execute this route, which isn't intended.
        guard profile.provider == "Facebook" else {
            response.status(.badRequest)
            return next()
        }
        let user = User(name: profile.displayName)
        if let picture = profile.photos?.first?.value {
            user.picture = URL(string: picture)
        }
        try persistence.add(user)
        try persistence.addFacebookCredential(for: user, facebookID: profile.id)
        if user.picture != nil {
            try storePicture(for: user)
        }
        // Redirect the user back to where he was (or to the home page).
        if let returnAddress = session["originalReturnTo"] as? String, !returnAddress.contains("authentication") {
            session.remove(key: "originalReturnTo")
            try response.redirect(returnAddress)
        } else {
            try response.redirect("/web/home")
        }
    }
    
    /**
     Stores a user's profile picture in cloud object storage and updates the link.
     Does nothing if cloud object storage is not configured.
     */
    private func storePicture(for user: User) throws {
        guard let id = user.id else {
            throw log(ServerError.unpersistedEntity)
        }
        guard let url = user.picture,
              CloudObjectStorage.isConfigured else {
            return
        }
        let cos = CloudObjectStorage()
        let object = "user/\(id).jpg"
        cos.storeImage(at: url, as: object) {
            user.picture = URL(string: "\(Settings.cloudObjectStorage.bucketURL!)/\(object)")
            do {
                try self.persistence.update(user)
            } catch {
                Log.warning("COS warning: failed to persist user \(id) after update.")
            }
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
}
