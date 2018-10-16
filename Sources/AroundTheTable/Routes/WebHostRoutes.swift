import Credentials
import Foundation
import Kitura
import LoggerAPI

extension Routes {
    
    /**
     Registers the web/host routes on the given router.
     */
    func configureWebHostRoutes(using router: Router, credentials: Credentials) {
        router.get("/", handler: host)
        router.get("select", handler: selectGame)
        router.all("activity", middleware: credentials)
        router.get("activity", handler: showCreateActivity)
        router.post("activity", handler: createActivity)
    }
    
    /**
     Shows the options for hosting an activity.
     */
    private func host(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        let base = try baseViewModel(for: request)
        try response.render("host", with: HostViewModel(base: base, query: "", error: false))
        next()
    }
    
    /**
     Queries BoardGameGeek and shows the results so the user can select a game to host.
     */
    private func selectGame(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) -> Void {
        guard let query = request.queryParameters["query"], query.count > 0 else {
            response.status(.badRequest)
            return next()
        }
        persistence.games(forQuery: query, exactMatchesOnly: request.queryParameters["exact"] == "on") {
            ids in
            do {
                guard ids.count > 0 else {
                    let base = try self.baseViewModel(for: request)
                    try response.render("host", with: HostViewModel(base: base, query: query, error: true))
                    return next()
                }
                try self.persistence.games(forIDs: ids) {
                    games in
                    do {
                        let base = try self.baseViewModel(for: request)
                        try response.render("host-game-selection", with: HostGameSelectionViewModel(
                            base: base,
                            results: games.sorted { $0.yearPublished > $1.yearPublished }
                        ))
                    } catch {
                        response.error = error
                    }
                    next()
                }
            } catch {
                response.error = error
                next()
            }
        }
    }
    
    /**
     After selecting a game to host, the user is presented with this form to create an activity.
     */
    private func showCreateActivity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard try authenticatedUser(for: request) != nil else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let game = request.queryParameters["game"], let gameID = Int(game) else {
            response.status(.badRequest)
            return next()
        }
        try persistence.game(forID: gameID) {
            game in
            guard let game = game else {
                response.status(.badRequest)
                return next()
            }
            do {
//                self.persistence.checkMediumPicture(for: game)
                let base = try self.baseViewModel(for: request)
                try response.render("host-activity", with: HostActivityViewModel(base: base, game: game))
            } catch {
                response.error = error
            }
            next()
        }
    }
    
    /**
     Creates an activity.
     */
    private func createActivity(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws -> Void {
        guard let user = try authenticatedUser(for: request) else {
            throw log(ServerError.missingMiddleware(type: Credentials.self))
        }
        guard let form = try? request.read(as: ActivityForm.self), form.isValid else {
            response.status(.badRequest)
            return next()
        }
        try persistence.game(forID: form.game) {
            game in
            guard let game = game else {
                response.status(.badRequest)
                return next()
            }
            let activity = Activity(host: user,
                                    name: form.name,
                                    game: game,
                                    playerCount: form.minPlayerCount...form.playerCount,
                                    prereservedSeats: form.prereservedSeats,
                                    date: form.date!,
                                    deadline: form.deadline!,
                                    location: form.location,
                                    info: form.info)
            do {
                try self.persistence.add(activity)
                self.storeImages(for: activity)
                guard let id = activity.id else {
                    response.error = ServerError.invalidState
                    return next()
                }
                try response.redirect("/web/activity/\(id.hexString)")
            } catch {
                response.error = error
                next()
            }
        }
    }
    
    /**
     Stores an activity's picture and thumbnail in cloud object storage and updates the links.
     Does nothing if cloud object storage is not configured.
     */
    private func storeImages(for activity: Activity) {
        guard let id = activity.id?.hexString,
              let picture = activity.picture,
              let thumbnail = activity.thumbnail,
              CloudObjectStorage.isConfigured else {
            return
        }
        // Helper function to get the file extension (including the leading dot) of an URL.
        func getExtension(for url: URL) -> String? {
            guard let file = url.absoluteString.components(separatedBy: "/").last,
                  let period = file.index(of: ".") else {
                return nil
            }
            return String(file[period...])
        }
        
        guard let pictureExtension = getExtension(for: picture),
              let thumbnailExtension = getExtension(for: thumbnail) else {
            Log.warning("COS warning: failed to get extensions for \(picture) and/or \(thumbnail).")
            return
        }
        let pictureObject = "activity/\(id)/picture\(pictureExtension)"
        let thumbnailObject = "activity/\(id)/thumbnail\(thumbnailExtension)"
        let cos = CloudObjectStorage()
//        cos.storeImage(at: picture, as: pictureObject) {
            cos.storeImage(at: thumbnail, as: thumbnailObject) {
//                activity.picture = URL(string: "\(Settings.cloudObjectStorage.bucketURL!)/\(pictureObject)")
                activity.thumbnail = URL(string: "\(Settings.cloudObjectStorage.bucketURL!)/\(thumbnailObject)")
                do {
                    try self.persistence.update(activity)
                } catch {
                    Log.warning("COS warning: failed to persist activity \(id) after update.")
                }
            }
//        }
    }
}
