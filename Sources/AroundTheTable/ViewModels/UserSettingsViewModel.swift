/**
 View model for **user-settings.stencil**.
 */
struct UserSettingsViewModel: Codable {
    
    let base: BaseViewModel
    let saved: Bool
    let userHasFacebookCredential: Bool
}
