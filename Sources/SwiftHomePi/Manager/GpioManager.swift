//
//  GpioManager.swift
//  
//
//  Created by yugo.sugiyama on 2022/07/24.
//

import Foundation
import SwiftyGPIO

final class GpioManager {
    static let shared = GpioManager()

    private let dataGpio: GPIO
    // serial clock
    private let sckGpio: GPIO

    init() {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        dataGpio = gpios[.P5]!
        
        sckGpio = gpios[.P6]!
        setup()
    }

    // Ref: https://www.slideshare.net/mostgood/swift-on-raspberry-pi-230094737
    func setup() {
        dataGpio.direction = .IN
        sckGpio.direction = .OUT
    }

    func readWeight() -> Int32 {
        sckGpio.value = 0
        var dataIn: UInt32 = 0
        for _ in 0..<24 {
            sckGpio.value = 1
            dataIn = (dataIn << 1) | UInt32(dataGpio.value)
            sckGpio.value = 0
        }

        if (dataIn == 0x7fffff || dataIn == 0x800000) {
            print("Invalid data detected: \(dataIn)")
            return 0
        }
        var signedData: Int32 = 0
        if (Int32(dataIn & 0x800000) == 1) {
            signedData = Int32(((dataIn ^ 0xffffff) + 1))
        } else {
            signedData = Int32(dataIn)
        }
        print("Converted 2\'s complemented value: \(signedData)")
        return Int32(signedData)
    }
}
