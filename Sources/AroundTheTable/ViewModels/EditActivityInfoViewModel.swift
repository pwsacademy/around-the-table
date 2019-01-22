import HTMLEntities

/**
 View model for **edit-activity-info.stencil**.
 */
struct EditActivityInfoViewModel: Codable {
    
    let base: BaseViewModel
    let id: Int
    let info: String
    
    init(base: BaseViewModel, activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        self.base = base
        self.id = id
        self.info = activity.info.htmlEscape()
    }
}
