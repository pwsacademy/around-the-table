struct SettingsViewContext: ViewContext {
    
    let base: [String : Any]
    var contents: [String : Any] = [:]
    
    init(base: [String: Any], user: User, saved: Bool) {
        self.base = base
        contents = ["saved": saved]
        if let location = user.location {
            contents["address"] = location.address
            contents["city"] = location.city
        }
    }
}
