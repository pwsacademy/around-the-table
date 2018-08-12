/**
 View model for **edit-activity-address.stencil**.
 */
struct EditActivityAddressViewModel: Codable {
    
    let base: BaseViewModel
    let id: String
    
    init(base: BaseViewModel, activity: Activity) throws {
        guard let id = activity.id else {
            throw log(ServerError.unpersistedEntity)
        }
        self.base = base
        self.id = id.hexString
    }
}
