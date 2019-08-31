// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "AroundTheTable",
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Health.git", from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.9.0"),
        .package(url: "https://github.com/IBM-Swift/swift-html-entities", from: "3.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.7.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsFacebook.git", from: "2.2.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", from: "3.3.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", from: "1.11.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", from: "6.0.0"),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", from: "4.1.4-swift5"),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", from: "2.1.0"),
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
