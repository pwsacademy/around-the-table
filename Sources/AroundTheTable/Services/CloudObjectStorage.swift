import Foundation
import LoggerAPI
import SwiftyRequest

/**
 Provides access to the Cloud Object Storage service.
 
 Cloud object storage is used to store user and game images.
 This avoids deep linking to BoardGameGeek and Facebook.
 */
class CloudObjectStorage {
    
    /**
     Whether cloud object storage is configured.
     This requires both an API key and a bucket URL.
     
     If both are not provided, cloud object storage will not be used.
     */
    static var isConfigured: Bool {
        return Settings.cloudObjectStorage.apiKey != nil
            && Settings.cloudObjectStorage.bucketURL != nil
    }
    
    /**
     An IAM (identity and access management) token.
     */
    private struct Token: Codable {
        
        /// The token.
        let access_token: String
        
        /// The token's expiration date, in seconds since 1970.
        let expiration: Int
    }
    
    private var token: Token?
    
    /**
     Whether a valid token is available.
     
     To avoid using an expired token, a token is considered invalid if it expires in less than one minute.
     */
    var hasValidToken: Bool {
        guard let token = token else {
            return false
        }
        let adjustedExpirationDate = Date(timeIntervalSince1970: Double(token.expiration - 60))
        return adjustedExpirationDate.compare(Date()) == .orderedDescending
    }
    
    /**
     Requests a token from the IAM (identity and access management) service.
     
     This requires an API key to be configured.
     If a valid token is available from a previous request, no new token will be requested.
     Once a token is available, it will be passed to the completion handler.
     
     If cloud object storage is not configured, or the request for a token failed,
     this method aborts and the completion handler is not called.
     */
    func getToken(completion: @escaping (String) -> Void) {
        guard CloudObjectStorage.isConfigured else {
            Log.warning("COS warning: called but not configured.")
            return
        }
        if hasValidToken {
            return completion(token!.access_token)
        }
        let request = RestRequest(method: .post, url: "https://iam.bluemix.net/identity/token")
        request.contentType = "application/x-www-form-urlencoded"
        let form = "apikey=\(Settings.cloudObjectStorage.apiKey!)&response_type=cloud_iam&grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey"
        request.messageBody =  form.data(using: .ascii)
        request.responseObject {
            (response: RestResponse<Token>) in
            guard case .success(let token) = response.result else {
                Log.warning("COS warning: IAM did not return a token.")
                return
            }
            self.token = token
            completion(token.access_token)
        }
    }
    
    /**
     Downloads data from a URL.
     
     If the data was downloaded successfully, it is passed to the completion handler.
     If the download failed, the completion handler will not be called.
     */
    func getData(from url: URL, completion: @escaping (Data) -> Void) {
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            guard let data = data else {
                Log.warning("COS warning: no data returned for URL \(url).")
                return
            }
            completion(data)
        }
        task.resume()
    }
    
    /**
     Stores image data in cloud object storage under the given object name.
     
     This method will first get an authorization token, then upload the data.
     If the data was uploaded successfully, the completion handler is called.
     
     If cloud object storage is not configured, or the upload failed,
     this method aborts and the completion handler is not called.
     
     - Parameter data: The image data. Only JPEG and PNG images are supported.
     - Parameter object: The name of the object to create or modify. Names can contain slashes to indicate a hierarchy, e.g. **user/123.jpg**, and should end in .png, .jpg or .jpeg. The object will have public read access.
     */
    func storeImage(_ data: Data, as object: String, completion: @escaping () -> Void) {
        guard CloudObjectStorage.isConfigured else {
            Log.warning("COS warning: called but not configured.")
            return
        }
        getToken {
            token in
            let request = RestRequest(method: .put, url: "\(Settings.cloudObjectStorage.bucketURL!)/\(object)")
            request.contentType = object.hasSuffix(".png") ? "image/png" : "image/jpeg"
            request.headerParameters["Authorization"] = "bearer \(token)"
            request.headerParameters["x-amz-acl"] = "public-read"
            request.messageBody = data
            request.responseVoid {
                response in
                guard case .success = response.result else {
                    Log.warning("COS warning: failed to upload \(object).")
                    return
                }
                completion()
            }
        }
    }
    
    /**
     Downloads data from a URL, then stores it in cloud object storage under the given object name.
     
     This is a convenience method that is implemented using `getData(from:completion:)` and `storeImage(_:as:completion:)`.
     */
    func storeImage(at url: URL, as object: String, completion: @escaping () -> Void) {
        getData(from: url) {
            data in
            self.storeImage(data, as: object, completion: completion)
        }
    }
    
    /**
     Deletes the object with the given name from cloud object storage.
     
     If the deletion was successful, the completion handler is called.
     
     If cloud object storage is not configured, or the deletion failed,
     this method aborts and the completion handler is not called.
     */
    func delete(object: String, completion: @escaping () -> Void) {
        guard CloudObjectStorage.isConfigured else {
            Log.warning("COS warning: called but not configured.")
            return
        }
        getToken {
            token in
            let request = RestRequest(method: .delete, url: "\(Settings.cloudObjectStorage.bucketURL!)/\(object)")
            request.headerParameters["Authorization"] = "bearer \(token)"
            request.responseVoid {
                response in
                guard case .success = response.result else {
                    Log.warning("COS warning: failed to delete \(object).")
                    return
                }
                completion()
            }
        }
    }
}
