import AroundTheTable
import Configuration
import HeliumLogger
import Kitura

let persistence = try! Persistence()
let router = Router()
Routes(persistence: persistence).configure(using: router)

HeliumLogger.use(.warning)

let configuration = ConfigurationManager().load(.environmentVariables)
Kitura.addHTTPServer(onPort: configuration.port, with: router)
print("Starting Kitura on port \(configuration.port)...")
Kitura.run()
