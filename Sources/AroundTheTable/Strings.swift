import Configuration

/**
 Typesafe wrapper around **strings-<locale>.json**.
 
 The methods in this type are used to build localized messages.
 */
enum Strings {
    
    private static let strings = ConfigurationManager().load(file: "Configuration/strings-\(Settings.locale).json", relativeFrom: .project)
    
    /**
     Builds a localized message to inform a player that a host approved his registration for an activity.
     */
    static func hostApprovedRegistration(for activity: Activity) -> String {
        return (strings["hostApprovedRegistration"] as! String)
            .replacingOccurrences(of: "<activity>", with: activity.name)
    }

    /**
     Builds a localized message to inform a player that a host cancelled an activity.
     */
    static func hostCancelled(_ activity: Activity) -> String {
        return (strings["hostCancelledActivity"] as! String)
            .replacingOccurrences(of: "<activity>", with: activity.name)
    }

    /**
     Builds a localized message to inform a player that a host cancelled his registration for an activity.
     */
    static func hostCancelledRegistration(for activity: Activity) -> String {
        return (strings["hostCancelledRegistration"] as! String)
            .replacingOccurrences(of: "<activity>", with: activity.name)
    }

    /**
     Builds a localized message to inform a player that a host changed the location of an activity.
     */
    static func hostChangedAddress(of activity: Activity) -> String {
        return (strings["hostChangedAddress"] as! String)
            .replacingOccurrences(of: "<activity>", with: activity.name)
            .replacingOccurrences(of: "<address>", with: activity.location.address)
    }

    /**
     Builds a localized message to inform a player that a host changed the date or time of an activity.
     */
    static func hostChangedDate(of activity: Activity) -> String {
        return (strings["hostChangedDate"] as! String)
            .replacingOccurrences(of: "<activity>", with: activity.name)
            .replacingOccurrences(of: "<date>", with: activity.date.formatted(format: "EEEE d MMMM"))
            .replacingOccurrences(of: "<time>", with: activity.date.formatted(format: "HH:mm"))
    }

    /**
     Builds a localized message to inform a host that a player cancelled his registration for an activity.
     */
    static func player(_ player: User, cancelledRegistrationFor activity: Activity) -> String {
        return (strings["playerCancelledRegistration"] as! String)
            .replacingOccurrences(of: "<player>", with: player.name)
            .replacingOccurrences(of: "<activity>", with: activity.name)
    }

    /**
     Builds a localized message to inform a host that a player's registration for an activity was automatically approved.
     */
    static func player(_ player: User, joined activity: Activity) -> String {
        return (strings["playerJoinedActivity"] as! String)
            .replacingOccurrences(of: "<player>", with: player.name)
            .replacingOccurrences(of: "<activity>", with: activity.name)
    }
    
    /**
     Builds a localized message to inform a host that a player submitted a registration for an activity.
     */
    static func player(_ player: User, sentRegistrationFor activity: Activity) -> String {
        return (strings["playerSentRegistration"] as! String)
            .replacingOccurrences(of: "<player>", with: player.name)
            .replacingOccurrences(of: "<activity>", with: activity.name)
    }
    
    /**
     Builds a localized message to inform a player that his registration for an activity was automatically approved.
     */
    static func registrationWasAutoApproved(for activity: Activity) -> String {
        return (strings["registrationWasAutoApproved"] as! String)
            .replacingOccurrences(of: "<activity>", with: activity.name)
    }
}
