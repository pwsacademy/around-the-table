import Foundation
import Kitura

/*
 A view context is responsible for mapping domain instances to a rendering context needed for a particular view.
 */
protocol ViewContext {
    
    /*
     A parent context. This is useful when template inheritance is used.
     */
    var base: [String: Any] { get }
    
    /*
     The contents of the rendering context for this particular view.
     */
    var contents: [String: Any] { get }
}

extension RouterResponse {
    
    /*
     Render a view context.
     The contents of the specified view context will be merged with its parent context.
     */
    @discardableResult
    func render(_ resource: String, context: ViewContext) throws -> RouterResponse {
        return try self.render(resource, context: context.base.appending(context.contents))
    }
}
