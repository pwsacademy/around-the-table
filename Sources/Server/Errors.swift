import Kitura
import LoggerAPI

/*
 Marks an error as `Loggable`.
 Together with the global `logAndThrow` function, this protocol helps in generating informative log messages.
 */
protocol Loggable {
    
    var message: String { get }
}

/*
 Log a `Loggable` error.
 Returns this error so it can be logged and stored in one go.
 */
func log<E: Error & Loggable>(_ error: E, function: String = #function, line: Int = #line, file: String = #file) -> E {
    Log.error(error.message, functionName: function, lineNum: line, fileName: file)
    return error
}

/*
 Log a `Loggable` error then throw it.
 This function is to be used instead of `throw` for all `Loggable` errors.
 By doing so, the error is logged when it is thrown.
 This provides us with more contextual information compared to logging an error when it is caught.
 */
func logAndThrow(_ error: Error & Loggable, function: String = #function, line: Int = #line, file: String = #file) throws -> Never {
    Log.error(error.message, functionName: function, lineNum: line, fileName: file)
    throw error
}

/*
 Errors related to downloading and parsing XML from BoardGameGeek.
 Used in `GameData` and `GameDataRepository`.
 */
enum BoardGameGeekError: Error, Loggable {
    
    case invalidElement(name: String, id: Int)
    case missingElement(name: String, id: Int)
    case missingOrInvalidData
    
    var message: String {
        switch self {
        case .invalidElement(let name, let id):
            return "BoardGameGeek error: invalid data for element \(name) in #\(id)."
        case .missingElement(let name, let id):
            return "BoardGameGeek error: missing element \(name) in #\(id)."
        case .missingOrInvalidData:
            return "BoardGameGeek error: request did not return valid XML."
        }
    }
}

/*
 Used when parsing BSON.
 */
enum BSONError: Error, Loggable {
    
    case invalidField(name: String)
    case missingField(name: String)
    
    var message: String {
        switch self {
        case .invalidField(let name):
            return "BSON error: invalid value for field \(name)."
        case .missingField(let name):
            return "BSON error: missing field \(name)."
        }
    }
}

/*
 Used for "this should not happen" errors.
 These errors (with the exception of `invalidRequest`) should be viewed as bugs.
 */
enum ServerError: Error, Loggable {
    
    case invalidRequest
    case invalidState
    case missingMiddleware(type: RouterMiddleware.Type)
    case missingSessionKey(name: String)
    case percentEncodingFailed
    case persistedEntity
    case unpersistedEntity
    
    var message: String {
        switch self {
        case .invalidRequest:
            return "Server error: invalid request."
        case .invalidState:
            return "Server error: invalid state."
        case .missingMiddleware(let type):
            return "Server error: missing middleware \(type)."
        case .missingSessionKey(let name):
            return "Server error: missing session key \(name)."
        case .percentEncodingFailed:
            return "Server error: percent encoding failed."
        case .persistedEntity:
            return "Server error: attempt to persist an already persisted entity."
        case .unpersistedEntity:
            return "Server error: attempt to modify or use an unpersisted entity."
        }
    }
}
