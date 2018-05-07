// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "AroundTheTable",
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .upToNextMinor(from: "1.7.0")),
        .package(url: "https://github.com/ddunn2/Kitura.git", .branch("testNewAPI")),
        .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsFacebook.git", .upToNextMinor(from: "2.1.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", .upToNextMinor(from: "3.1.0")),
        .package(url: "https://github.com/ddunn2/Kitura-StencilTemplateEngine.git", .branch("testNewAPI")),
        .package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", .upToNextMinor(from: "6.0.0")),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", .upToNextMinor(from: "4.1.0")),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", .upToNextMinor(from: "1.1.0"))
    ],
    targets: [
        .target(name: "Server", dependencies: [
            "HeliumLogger",
            "Kitura",
            "CredentialsFacebook",
            "KituraStencil",
            "CloudFoundryEnv",
            "MongoKitten",
        ])
    ]
)
