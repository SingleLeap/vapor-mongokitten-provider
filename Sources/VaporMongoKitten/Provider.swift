import Vapor

public final class Provider: Vapor.Provider {
    public let driver: MongoKittenDriver
    public let database: Database

    public enum Error: Swift.Error {
        case config(String)
        case unsupported(String)
    }

    public init(withMongoURL mongoURL: String) throws {
        let driver = try MongoKittenDriver(mongoURL: mongoURL)
        self.driver = driver
        self.database = Fluent.Database(driver)
    }

    public convenience init(database: String, user: String, password: String, host: String, port: Int) throws {
        guard let escapedUser = user.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            throw Error.unsupported("Failed to percent encode username")
        }
        guard let escapedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            throw Error.unsupported("Failed to percent encode password")
        }
        try self.init(withMongoURL: "mongodb://\(escapedUser):\(escapedPassword)@\(host):\(port)")
    }

    public convenience init(config: Config) throws {
        if let url = config["url"]?.string {
            try self.init(withMongoURL: url)

        } else {

            guard let mongo = config["mongo"]?.object else {
                throw Error.config("No mongo.json config file.")
            }

            guard let database = mongo["database"]?.string else {
                throw Error.config("No 'database' key in mongo.json config file.")
            }

            guard let user = mongo["user"]?.string else {
                throw Error.config("No 'user' key in mongo.json config file.")
            }

            guard let password = mongo["password"]?.string else {
                throw Error.config("No 'password' key in mongo.json config file.")
            }

            let host = mongo["host"]?.string ?? "localhost"
            let port = mongo["port"]?.int ?? 27017

            try self.init(
              database: database,
              user: user,
              password: password,
              host: host,
              port: port
            )
        }
    }

    public func boot(_ drop: Droplet) {
        drop.database = database
    }

    public func afterInit(_ drop: Droplet) {

    }

    public func beforeRun(_ drop: Droplet) {

    }
}
