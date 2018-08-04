import Kitura
import LoggerAPI

/**
 Marks an error as `Loggable`.
 
 Together with the global `log(...)` function, this protocol helps in generating informative log messages.
 */
protocol Loggable: Error {
    
    /// The message to log when this error is thrown.
    var message: String { get }
}

/**
 Logs a `Loggable` error.
 
 This function should be called before throwing a `Loggable` error.
 By doing so, the error is logged when it is thrown.
 This provides more contextual information compared to logging an error when it is caught.
 
 - Returns: The error that was passed in, so it can be logged and thrown (or stored) in one statement.
 */
func log<E: Loggable>(_ error: E, function: String = #function, line: Int = #line, file: String = #file) -> E {
    Log.error(error.message, functionName: function, lineNum: line, fileName: file)
    return error
}

/**
 Errors related to parsing BSON.
 */
enum BSONError: Loggable {
    
    /// A field contains invalid content.
    case invalidField(name: String)
    
    /// A required field is missing.
    case missingField(name: String)
    
    /// The message to log when this error is thrown.
    var message: String {
        switch self {
        case .invalidField(let name):
            return "BSON error: invalid value for field \(name)."
        case .missingField(let name):
            return "BSON error: missing field \(name)."
        }
    }
}

/**
 Errors related to downloading and parsing XML from BoardGameGeek.
 */
enum GeekError: Loggable {
    
    /// An element contains invalid data.
    case invalidElement(name: String, id: Int)
    
    /// A required element is missing.
    case missingElement(name: String, id: Int)
    
    /// The message to log when this error is thrown.
    var message: String {
        switch self {
        case .invalidElement(let name, let id):
            return "BGG error: invalid element \(name) in #\(id)."
        case .missingElement(let name, let id):
            return "BGG error: missing element \(name) in #\(id)."
        }
    }
}

/**
 Errors that should be viewed as bugs.
 */
enum ServerError: Loggable {
    
    /// Conflicting data was detected.
    case conflict
    
    /// An invalid state was detected.
    case invalidState
    
    /// A required middleware did not execute.
    case missingMiddleware(type: RouterMiddleware.Type)
    
    /// An attempt was made to persist an already persisted entity (duplicate id).
    case persistedEntity
    
    /// An attempt was made to modify or use an unpersisted entity (missing id).
    case unpersistedEntity
    
    /// The message to log when this error is thrown.
    var message: String {
        switch self {
        case .conflict:
            return "Server error: conflicting data."
        case .invalidState:
            return "Server error: invalid state."
        case .missingMiddleware(let type):
            return "Server error: missing middleware \(type)."
        case .persistedEntity:
            return "Server error: attempt to persist an already persisted entity (duplicate id)."
        case .unpersistedEntity:
            return "Server error: attempt to modify or use an unpersisted entity (missing id)."
        }
    }
}
