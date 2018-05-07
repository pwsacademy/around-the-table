import Configuration
import Foundation

/*
 Typesafe wrapper around `strings-locale.json`.
 */
enum Strings {
    
    private static let strings = ConfigurationManager().load(file: "Configuration/strings-\(Settings.locale).json", relativeFrom: .project)
    
    static func facebookAnnouncement(for game: Game) -> String {
        return (strings["facebookGameAnnouncement"] as! String)
            .replacingOccurrences(of: "<title>", with: game.data.name)
            .replacingOccurrences(of: "<host>", with: game.host.name)
            .replacingOccurrences(of: "<date>", with: game.date.formatted(format: "EEEE d MMMM"))
            .replacingOccurrences(of: "<time>", with: game.date.formatted(format: "HH:mm"))
            .replacingOccurrences(of: "<city>", with: game.location.city)
            .replacingOccurrences(of: "<country>", with: game.location.country)
            .replacingOccurrences(of: "<info>", with: game.info)
    }
}
