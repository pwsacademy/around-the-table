/**
 Form for editing an activity's player count.
 */
struct EditActivityPlayerCountForm: Codable {
    
    let playerCount: Int
    let minPlayerCount: Int
    let prereservedSeats: Int
    
    var isValid: Bool {
        return minPlayerCount <= playerCount && prereservedSeats <= playerCount
    }
}
