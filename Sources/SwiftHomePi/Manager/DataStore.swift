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

    func updateDeviceInfo(deviceInfoModel: DeviceInfoModel) async throws {
        let deviceInfoDBModel = deviceInfoModel.asDBModel
        if let deviceInfoModel = try await DeviceInfoDBModel.query(on: db)
            .filter(\.$deviceId == deviceInfoDBModel.deviceId).all().first {
            deviceInfoModel.deviceId = deviceInfoModel.deviceId
            try await deviceInfoModel.save(on: db)
            print("DataStore: \(deviceInfoModel.deviceId) is updated!")
        } else {
            try await deviceInfoDBModel.create(on: db)
            print("DataStore: \(deviceInfoModel.deviceId) is created!")
        }
    }

    func fetchDeviceInfo() async throws -> DeviceInfoModel? {
        try await DeviceInfoDBModel.query(on: db).all()
            .map({ DeviceInfoModel(
                deviceId: $0.deviceId,
                deviceLatitude: $0.deviceLatitude,
                deviceLongitude: $0.deviceLongitude,
                absoluteAltimeter: $0.absoluteAltimeter) })
            .first
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

    func updateLoadStatus(isRemoved: Bool) async throws {
        let loadStatusDBModel = LoadStatusDBModel(isRemoved: isRemoved)
        if let loadStatusModel = try await LoadStatusDBModel.query(on: db).all().first {
            loadStatusModel.isRemoved = loadStatusDBModel.isRemoved
            try await loadStatusDBModel.save(on: db)
            print("DataStore: \(loadStatusDBModel.isRemoved) is updated!")
        } else {
            try await loadStatusDBModel.create(on: db)
            print("DataStore: \(loadStatusDBModel.isRemoved) is created!")
        }
    }

    func fetchLoadStatus() async throws -> Bool {
        return try await LoadStatusDBModel.query(on: db).all()
            .compactMap({ $0.isRemoved }).first ?? false
    }
}
