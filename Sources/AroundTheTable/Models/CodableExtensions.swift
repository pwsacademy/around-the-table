/**
 Adds `Codable` conformance to `ClosedRange`.
 
 A `ClosedRange` is coded by coding the `lowerBound` and `upperBound` properties.
 */
extension ClosedRange: Codable where Bound: Codable {

    enum CodingKeys: CodingKey {
        case lowerBound
        case upperBound
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowerBound, forKey: .lowerBound)
        try container.encode(upperBound, forKey: .upperBound)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lowerBound = try container.decode(Bound.self, forKey: .lowerBound)
        let upperBound = try container.decode(Bound.self, forKey: .upperBound)
        self = lowerBound...upperBound
    }
}
