import Foundation
import Vapor
import SwiftHomeCredentials
import SwiftHomeCore
import SwiftHomeServerCore

final class WebSocketManager {
    private var webSocket: WebSocket?
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    private let serverConfig: ServerConfiguration = .localHost
    static let shared = WebSocketManager()

    private init() {}

    func setup() {
        let basicAuthentication = SwiftHomeCredentials.basicAuthentication
        let plainString = "\(basicAuthentication.id):\(basicAuthentication.password)".data(using: String.Encoding.utf8)
        let credential = plainString?.base64EncodedString(options: [])
        let headers: Vapor.HTTPHeaders = [
            "Authorization": "Basic \(credential!)"
        ]
        _ = WebSocket.connect(to: "\(serverConfig.URLString(type: .webSocket))/\(EndPointKind.nfcId.webSocketEndPoint)", headers: headers, on: eventLoopGroup) { [weak self] ws in
            guard let self = self else { return }
            print("WebSocket is conected!")
            // Called when App-Server WebSocket is connected.
            self.webSocket = ws
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
                        if id == savedNfcId.nfcId {
                            print("This card is registered!")
                        } else {
                            print("This card is not registered")
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}
