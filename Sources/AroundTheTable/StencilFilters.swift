import Stencil

/**
 Additional filters for Stencil.
 */
enum StencilFilters {
    
    /**
     Registers all filters on the given `Extension`.
     */
    static func register(on stencil: Extension) {
        stencil.registerFilter("count", filter: count)
        stencil.registerFilter("first", filter: first)
        stencil.registerFilter("max", filter: max)
        stencil.registerFilter("previous", filter: previous)
        stencil.registerFilter("next", filter: next)
    }
    
    /**
     Returns the number of elements in an array.
     */
    static func count(_ value: Any?) -> Any? {
        switch value {
        case let array as [Any]:
            return array.count
        default:
            return nil
        }
    }
    
    /**
     Returns the first element of an array.
     */
    static func first(_ value: Any?) -> Any? {
        switch value {
        case let array as [Any]:
            return array.first
        default:
            return nil
        }
    }
    
    /**
     Returns the maximum value in an array of integers.
     */
    static func max(_ value: Any?) -> Any? {
        switch value {
        case let array as [Int]:
            return array.max()
        default:
            return nil
        }
    }
    
    /**
     Returns the predecessor of a given integer.
     */
    static func previous(_ value: Any?) -> Any? {
        switch value {
        case let number as Int:
            return number - 1
        default:
            return nil
        }
    }
    
    /**
     Returns the successor of a given integer.
     */
    static func next(_ value: Any?) -> Any? {
        switch value {
        case let number as Int:
            return number + 1
        default:
            return nil
        }
    }
}
