/*
 Additional filters for Stencil.
 Don't forget to register these in `main.swift`.
 */
enum StencilFilters {
    
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
