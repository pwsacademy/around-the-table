// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "AroundTheTable",
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Health.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .upToNextMinor(from: "1.7.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", .upToNextMinor(from: "2.4.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsFacebook.git", .upToNextMinor(from: "2.2.0")),
        .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", .upToNextMinor(from: "3.2.0")),
        .package(url: "https://github.com/svanimpe/Kitura-StencilTemplateEngine.git", .branch("template-patch")),
        .package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", .upToNextMinor(from: "6.0.0")),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", .upToNextMinor(from: "4.1.0")),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", .upToNextMinor(from: "1.1.0")),
    ],
    targets: [
        .target(name: "Main", dependencies: [
            "AroundTheTable"
        ]),
        .target(name: "AroundTheTable", dependencies: [
            "Health",
            "HeliumLogger",
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
