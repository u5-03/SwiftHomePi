import Vapor
import SwiftHomeServerCore
import SwiftHomeCredentials
import SwiftHomeCore

_ = DataStore.shared
WebSocketManager.shared.setup()

GpioManager.shared.setup()
var count = 0
while(count <= 60) {
    count += 1
    sleep(1)
    print("Weight: \(GpioManager.shared.readWeight())")
    print("Count: \(count)")
//    print(value + value)
}

