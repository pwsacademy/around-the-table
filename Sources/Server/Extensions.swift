extension Dictionary {

    mutating func append(_ dictionary: [Key: Value]) {
        for (key, value) in dictionary {
            self[key] = value
        }
    }
    
    func appending(_ dictionary: [Key: Value]) -> [Key: Value] {
        var result = self
        for (key, value) in dictionary {
            result[key] = value
        }
        return result
    }
}

extension Sequence where Iterator.Element: Equatable {
    
    func withoutDuplicates() -> [Iterator.Element] {
        return reduce([]) {
            elements, element in
            return elements.contains(element) ? elements : elements + [element]
        }
    }
}
