import Foundation
import Vapor
import SwiftHomeCredentials
import SwiftHomeCore
import SwiftHomeServerCore

final class WebSocketManager {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    private let serverConfig: ServerConfiguration = .server
    var didEventNotify: ((EndPointKind) ->  Void)?
    // WebSocket
    private var deviceInfoWebSocket: WebSocket?
    private var nfcIdWebSocket: WebSocket?
    private var inHomeWebSocket: WebSocket?
    private var notificationWebSocket: WebSocket?
    static let shared = WebSocketManager()

    private init() {}

    func setup() {
        let basicAuthentication = SwiftHomeCredentials.basicAuthentication
        let plainString = "\(basicAuthentication.id):\(basicAuthentication.password)".data(using: .utf8)
        let credential = plainString?.base64EncodedString(options: [])
        let headers: Vapor.HTTPHeaders = [
            "Authorization": "Basic \(credential!)",

        ]
        // device info
        _ = WebSocket.connect(to: "\(serverConfig.URLString(type: .webSocket))/\(EndPointKind.deviceInfo.webSocketEndPoint)", headers: headers, on: eventLoopGroup) { [weak self] ws in
            guard let self = self else { return }
            print("WebSocket is conected!")
            // Called when App-Server WebSocket is connected.
            self.deviceInfoWebSocket = ws
            ws.onText { ws, text in
                Task {
                    let jsonData = text.data(using: .utf8)!
                    do {
                        let response = try JSONDecoder().decode(DeviceInfoModel.self, from: jsonData)
                        try await DataStore.shared.updateDeviceInfo(deviceInfoModel: response)
                        let isInHome = await StatusStore.isInHome
                        let isInHomeString = (isInHome ? WebSocketStatus.inHome : WebSocketStatus.notInHome).rawValue
                        try await self.inHomeWebSocket?.send(isInHomeString)
                    } catch {
                        print(error)
                    }
                }
            }
        }

        // nfc ID
        _ = WebSocket.connect(to: "\(serverConfig.URLString(type: .webSocket))/\(EndPointKind.nfcId.webSocketEndPoint)", headers: headers, on: eventLoopGroup) { [weak self] ws in
            guard let self = self else { return }
            print("WebSocket is conected!")
            // Called when App-Server WebSocket is connected.
            self.nfcIdWebSocket = ws
            ws.onText { ws, text in
                Task {
                    let jsonData = text.data(using: .utf8)!
                    do {
                        let response = try JSONDecoder().decode(NfcIdModel.self, from: jsonData)
                        try await DataStore.shared.updateNfcId(nfcIdModel: response)

                        let id = PythonCall().readNfcId()
                        guard let savedNfcId = try await DataStore.shared.fetchNfcId() else {
                            print("Cannot find NfcId in sqlite")
                            return
                        }
                        StatusStore.isSuicaAuthenticated = id == savedNfcId.nfcId
                    } catch {
                        StatusStore.isSuicaAuthenticated = false
                        print(error)
                    }
                }
            }
            ws.onClose.whenComplete { result in
                switch result {
                case .success:
                    StatusStore.isSuicaAuthenticated = false
                case .failure(let error):
                    print(error)
                }
            }
        }

        // in home
        _ = WebSocket.connect(to: "\(serverConfig.URLString(type: .webSocket))/\(EndPointKind.isInHome.webSocketEndPoint)", headers: headers, on: eventLoopGroup) { [weak self] ws in
            guard let self = self else { return }
            print("WebSocket is conected!")
            // Called when App-Server WebSocket is connected.
            self.inHomeWebSocket = ws
        }
        // event notificatoin
        _ = WebSocket.connect(to: "\(serverConfig.URLString(type: .webSocket))/\(EndPointKind.eventNotification.webSocketEndPoint)", headers: headers, on: eventLoopGroup) { [weak self] ws in
            guard let self = self else { return }
            print("WebSocket is conected!")
            // Called when App-Server WebSocket is connected.
            self.notificationWebSocket = ws
            ws.onText { ws, text in
                guard let endPointKind = EndPointKind.allCases.first(where: { $0.webSocketEndPoint == text }) else { return }
                print(endPointKind.webSocketEndPoint)
                self.didEventNotify?(endPointKind)
            }
        }
    }
}
