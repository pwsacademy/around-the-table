import Kitura
import KituraSession
import SwiftyJSON

/*
 Saves the user's current location.
 The user is asked to allow geolocation on the welcome page.
 This middleware is used there to store the provided location in the current session.
 */
struct SaveLocationMiddleware: RouterMiddleware {
    
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard let session = request.session else {
            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
        }
        let coordinates: JSON
        if let latitudeString = request.queryParameters["latitude"],
           let latitude = Double(latitudeString),
           let longitudeString = request.queryParameters["longitude"],
           let longitude = Double(longitudeString) {
            coordinates = [
                "latitude": latitude,
                "longitude": longitude,
                "geolocated": true
            ]
        } else {
            // Use the default location if geolocation was not available or allowed.
            coordinates = [
                "latitude": Settings.defaultCoordinates.latitude,
                "longitude": Settings.defaultCoordinates.longitude,
                "geolocated": false
            ]
        }
        session["coordinates"] = coordinates
        next()
    }
}

/*
 Loads the user's current location from the current session into the `request.userInfo` dictionary.
 Also loads related settings like the list of supported countries and the Google API key.
 */
struct LocationMiddleware: RouterMiddleware {
    
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard let session = request.session else {
            try logAndThrow(ServerError.missingMiddleware(type: Session.self))
        }
        guard let latitude = session["coordinates"]["latitude"].double else {
            try logAndThrow(ServerError.missingSessionKey(name: "coordinates.latitude"))
        }
        guard let longitude = session["coordinates"]["longitude"].double else {
            try logAndThrow(ServerError.missingSessionKey(name: "coordinates.longitude"))
        }
        guard let geolocated = session["coordinates"]["geolocated"].bool else {
            try logAndThrow(ServerError.missingSessionKey(name: "coordinates.geolocated"))
        }
        request.userInfo["coordinates"] = [
            "latitude": latitude,
            "longitude": longitude,
            "geolocated": geolocated
        ]
        request.userInfo["countries"] = "[\(Settings.countries.map { "\"\($0)\"" }.joined(separator: ", "))]" // Builds a JSON array.
        request.userInfo["googleAPIKey"] = Secrets.googleAPIKey
        next()
    }
}
