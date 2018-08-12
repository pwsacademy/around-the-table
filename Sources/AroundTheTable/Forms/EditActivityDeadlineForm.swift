/**
 Form for editing an activity's deadline.
 */
struct EditActivityDeadlineForm: Codable {

    let deadlineType: String
    
    var isValid: Bool {
        return ["one hour", "one day", "two days", "one week"].contains(deadlineType)
    }
}
