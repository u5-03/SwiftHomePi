import Foundation
import Vapor
import Fluent
import FluentSQLiteDriver
import SwiftHomeServerCore
import SwiftHomeCore

// Ref: https://zenn.dev/sun_yryr/scraps/e6a34d5026eb57
final class DataStore {

    let logger: Logger
    let eventLoopGroup: EventLoopGroup
    let threadPool: NIOThreadPool
    let databases: Databases
    private var db: Database {
        return databases.database(logger: logger, on: eventLoopGroup.next())!
    }
    static let shared = DataStore(configure: .sqlite(.file("db.sqlite")), id: .sqlite)

    private init(configure: DatabaseConfigurationFactory, id: DatabaseID) {
        logger = Logger(label: "swift-home.main")
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        threadPool = NIOThreadPool(numberOfThreads: 1)
        databases = Databases(threadPool: threadPool, on: eventLoopGroup)
        databases.use(configure, as: id)

        let nfcIdMigration = CreateMfcIdModel()
        _ = nfcIdMigration.prepare(on: db)
    }

    deinit {
        databases.shutdown()
    }

    func updateNfcId(nfcIdModel: NfcIdModel) async throws {
        let nfcIdDBModel = nfcIdModel.asDBModel
        if let nfcIdModel = try await NfcIdDBModel.query(on: db)
            .filter(\.$nfcId == nfcIdDBModel.nfcId).all().first {
            nfcIdModel.nfcId = nfcIdDBModel.nfcId
            try await nfcIdModel.save(on: db)
            print("DataStore: \(nfcIdModel.nfcId) is updated!")
        } else {
            try await nfcIdDBModel.create(on: db)
            print("DataStore: \(nfcIdModel.nfcId) is created!")
        }
    }

    func fetchNfcId() async throws -> NfcIdModel? {
        try await NfcIdDBModel.query(on: db).all()
            .map({ NfcIdModel(nfcId: $0.nfcId) }).first
    }
}
