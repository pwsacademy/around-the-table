import PackageDescription

let package = Package(
    name: "AroundTheTable",
    targets: [
        Target(name: "Server", dependencies: [])
    ],
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1),
        .Package(url: "https://github.com/svanimpe/Kitura-CredentialsFacebook.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/Kitura-Session.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", majorVersion: 4),
        .Package(url: "https://github.com/OpenKitten/MongoKitten.git", majorVersion: 4)
    ]
)
