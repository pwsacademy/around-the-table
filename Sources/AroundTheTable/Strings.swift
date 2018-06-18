import Configuration

/**
 Typesafe wrapper around **strings-<locale>.json**.
 
 The methods in this type are used to build localized messages.
 */
enum Strings {
    
    private static let strings = ConfigurationManager().load(file: "Configuration/strings-\(Settings.locale).json", relativeFrom: .project)
    
    /**
     Builds a localized message to use when a host approves a registration for an activity.
     */
    static func hostApprovedRegistration(for activity: Activity) -> String {
        return strings["hostApprovedRegistration"] as! String
    }

    /**
     Builds a localized message to use when a host cancels an activity.
     */
    static func hostCancelled(_ activity: Activity) -> String {
        return strings["hostCancelledActivity"] as! String
    }

    /**
     Builds a localized message to use when a host cancels a registration for an activity.
     */
    static func hostCancelledRegistration(for activity: Activity) -> String {
        return strings["hostCancelledRegistration"] as! String
    }

    /**
     Builds a localized message to use when a host changes the location of an activity.
     */
    static func hostChangedAddress(of activity: Activity) -> String {
        return (strings["hostChangedAddress"] as! String)
            .replacingOccurrences(of: "<address>", with: activity.location.address)
    }

    /**
     Builds a localized message to use when a host changes the date or time of an activity.
     */
    static func hostChangedDate(of activity: Activity) -> String {
        return (strings["hostChangedDate"] as! String)
            .replacingOccurrences(of: "<date>", with: activity.date.formatted(format: "EEEE d MMMM"))
            .replacingOccurrences(of: "<time>", with: activity.date.formatted(format: "HH:mm"))
    }

    /**
     Builds a localized message to use when a player cancels a registration for an activity.
     */
    static func playerCancelledRegistration(for activity: Activity) -> String {
        return strings["playerCancelledRegistration"] as! String
    }

    /**
     Builds a localized message to use when a player submits a registration for an activity.
     */
    static func playerSentRegistration(for activity: Activity) -> String {
        return strings["playerSentRegistration"] as! String
    }
}
