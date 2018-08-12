import Foundation

/**
 View model for **edit-activity-datetime.stencil**.
 */
struct EditActivityDateTimeViewModel: Codable {
    
    let base: BaseViewModel
    let id: String
    
    struct DateViewModel: Codable {
        
        let day: Int
        let month: Int
        let year: Int
        let hour: Int
        let minute: Int
        
        init(_ components: DateComponents) {
            day = components.day!
            month = components.month!
            year = components.year!
            hour = components.hour!
            minute = components.minute!
        }
    }
    
    let date: DateViewModel
    
    init(base: BaseViewModel, activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        self.base = base
        self.id = id.hexString
        let components = Calendar(identifier: .gregorian).dateComponents(in: Settings.timeZone, from: activity.date)
        self.date = DateViewModel(components)
    }
}
