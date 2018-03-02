// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "AroundTheTable",
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .upToNextMinor(from: "1.7.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", .upToNextMinor(from: "2.2.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsFacebook.git", .upToNextMinor(from: "2.1.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", .upToNextMinor(from: "3.0.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", .upToNextMinor(from: "1.8.0")),
        .package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", .upToNextMinor(from: "6.0.0")),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", .upToNextMinor(from: "4.1.0")),
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
