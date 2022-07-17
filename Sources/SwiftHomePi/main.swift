import Vapor
import SwiftHomeServerCore
import SwiftHomeCredentials
import SwiftHomeCore
import Alamofire

WebSocketManager.shared.didEventNotify = { endPoint in
    if endPoint != .doorOpenDetected { return }
    // when switchbot detected door open, play sound and control switchbot device
    Task {
        if await !StatusStore.isAllAuthPassed {
            ShellCall().playWarningSound()
            DeviceCall.postSwitchBot(interval: 0)
        }
    }
}

_ = DataStore.shared
WebSocketManager.shared.setup()

#if os(Linux)
GpioManager.shared.setup()
GpioManager.shared.observeHumanMoved { didDetected in
    // This code is for Demo in iOSDC2022
    if didDetected {
        print("Human detected!")
        // This interval is for Demo
        let interval: UInt32 = 5
        DeviceCall.postSwitchBot(interval: interval)
        sleep(interval)
        ShellCall().playWarningSound()
        sleep(interval)
        FirebaseManager.sendMessage()
    } else {
        print("Human Not detected!")
    }
    // This is expected code. Comment out for demo.
//    Task {
//        if didDetected && await !StatusStore.isAllAuthPassed {
//            ShellCall().playWarningSound()
//            DeviceCall.postSwitchBot(interval: 0)
//            FirebaseManager.sendMessage()
//        }
//    }
}
#endif
GpioManager.shared.observeLoad(isPlaced: false) { isPlaced in
    StatusStore.isLoadPlaced = isPlaced
}
while(true) {}
