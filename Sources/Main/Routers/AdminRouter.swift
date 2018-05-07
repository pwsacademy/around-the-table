import Foundation
import Kitura
import KituraNet
import LoggerAPI

func configureAdminRouter(using router: Router) {
    
    router.get("facebook-token") {
        request, response, next in
        let appID = Settings.facebook.appID
        let callbackURL: String
        if let customDomainName = Settings.customDomainName, !configuration.isLocal {
            callbackURL = "https://\(customDomainName)/admin/facebook-token/callback"
        } else {
            callbackURL = "\(configuration.url)/admin/facebook-token/callback"
        }
        try response.redirect("https://www.facebook.com/dialog/oauth?client_id=\(appID)&redirect_uri=\(callbackURL)&scope=public_profile,publish_actions,user_managed_groups&response_type=code")
        next()
    }
    
    router.get("facebook-token/callback") {
        request, response, next in
        guard let code = request.queryParameters["code"] else {
            Log.error("No code received from Facebook")
            return
        }
        let appID = Settings.facebook.appID
        let appSecret = Secrets.facebookAppSecret
        let callbackURL: String
        if let customDomainName = Settings.customDomainName, !configuration.isLocal {
            callbackURL = "https://\(customDomainName)/admin/facebook-token/callback"
        } else {
            callbackURL = "\(configuration.url)/admin/facebook-token/callback"
        }
        let request = HTTP.request("https://graph.facebook.com/v2.12/oauth/access_token?client_id=\(appID)&client_secret=\(appSecret)&redirect_uri=\(callbackURL)&code=\(code)") {
            response in
            guard let response = response, response.statusCode == .OK else {
                Log.error("Request for Facebook access token failed")
                return
            }
            do {
                var data = Data()
                try response.readAllData(into: &data)
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let token = json["access_token"] as? String,
                      let lifetime = json["expires_in"] as? Int else {
                    Log.error("Request for Facebook access token failed")
                    return
                }
                let expireDate = Calendar(identifier: .gregorian).date(byAdding: .second, value: lifetime, to: Date())!
                try collection(.admin).update(["_id": "facebook"], to: ["token": token, "expires": expireDate], upserting: true)
            } catch {
                Log.error("Request for Facebook access token failed")
            }
        }
        request.end()
        response.send("Token updated")
    }
}

