import Stencil

/*
 Additional filters for Stencil.
 */
enum StencilFilters {
    
    static func register(on stencil: Extension) {
        stencil.registerFilter("count", filter: count)
        stencil.registerFilter("first", filter: first)
        stencil.registerFilter("max", filter: max)
        stencil.registerFilter("previous", filter: previous)
        stencil.registerFilter("next", filter: next)
    }
    
    static func count(_ value: Any?) -> Any? {
        switch value {
        case let array as [Int]:
            return array.count
        case let array as [String]:
            return array.count
        default:
            return nil
        }
    }
    
    static func first(_ value: Any?) -> Any? {
        switch value {
        case let array as [Int]:
            return array.first
        case let array as [String]:
            return array.first
        default:
            return nil
        }
    }
    
    static func max(_ value: Any?) -> Any? {
        switch value {
        case let array as [Int]:
            return array.max()
        default:
            return nil
        }
    }
    
    static func previous(_ value: Any?) -> Any? {
        switch value {
        case let number as Int:
            return number - 1
        default:
            return nil
        }
    }
    
    static func next(_ value: Any?) -> Any? {
        switch value {
        case let number as Int:
            return number + 1
        default:
            return nil
        }
    }
}
