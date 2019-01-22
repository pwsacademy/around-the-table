// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "AroundTheTable",
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Health.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .upToNextMinor(from: "1.8.0")),
        .package(url: "https://github.com/IBM-Swift/swift-html-entities", .upToNextMinor(from: "3.0.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", .upToNextMinor(from: "2.6.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsFacebook.git", .upToNextMinor(from: "2.2.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", .upToNextMinor(from: "3.3.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", .upToNextMinor(from: "1.11.0")),
        .package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", .upToNextMinor(from: "6.0.0")),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", .upToNextMinor(from: "4.1.0")),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", .upToNextMinor(from: "2.0.0")),
    ],
    targets: [
        .target(name: "Main", dependencies: [
            "AroundTheTable"
        ]),
        .target(name: "AroundTheTable", dependencies: [
            "Health",
            "HeliumLogger",
            "HTMLEntities",
            "Kitura",
            "CredentialsFacebook",
            "KituraSession",
            "KituraStencil",
            "CloudFoundryEnv",
            "MongoKitten",
            "SwiftyRequest"
        ]),
        .testTarget(name: "AroundTheTableTests", dependencies: [
            "AroundTheTable"
        ])
    ]
)
