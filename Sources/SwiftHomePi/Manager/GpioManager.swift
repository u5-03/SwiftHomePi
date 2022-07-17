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
    // Not exact value
    private let refernceUnit = 465.375
    private let defaultLoadValue = 199273.375

    // Load sensor
    private let dataGpio: GPIO
    // serial clock
    private let sckGpio: GPIO
    private var isLoadPlaced = false
    // Human ensor
    private let humanSensorGpio: GPIO
    private let humanSensorLedGpio: GPIO
    // connectWithOtherRasPi
    let gpio: GPIO
    let gpio2: GPIO
    let gpio21Led: GPIO
    let motorGpio: GPIO

    init() {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        
        dataGpio = gpios[.P5]!
        sckGpio = gpios[.P6]!
        gpio = gpios[.P21]!
        gpio2 = gpios[.P25]!

        gpio21Led = gpios[.P21]!
        gpio21Led.direction = .OUT

        // Human sensor
        humanSensorGpio = gpios[.P25]!
        humanSensorLedGpio = gpios[.P16]!

        motorGpio = gpios[.P13]!
        motorGpio.direction = .OUT

        // setup
        setupHumanSensor()
        setupLoadSensor()
    }

    func setup() {
        connectWithOtherRasPi()
    }
}

extension GpioManager {
    func connectWithOtherRasPi() {
        gpio.direction = .OUT
        gpio2.direction = .IN
        gpio2.pull = .neither

        gpio2.onChange { gpio in
            print(gpio.value)
        }
        gpio.value = 0
        sleep(2)
        gpio.value = 1
        sleep(2)
        gpio.value = 0
    }
}

// Human Sensor
extension GpioManager {
    func setupHumanSensor() {
        humanSensorGpio.direction = .IN
        humanSensorLedGpio.direction = .OUT
        humanSensorLedGpio.value = 0
    }

    func observeHumanMoved(completion: @escaping (Bool) -> Void) {
        humanSensorGpio.onChange { gpio in
            if gpio.value == 1 {
                // Human detected
                self.humanSensorLedGpio.value = 1
                completion(true)
            } else {
                self.humanSensorLedGpio.value = 0
                completion(false)
            }
        }
    }
}

// Load sensor
// Ref: https://www.slideshare.net/mostgood/swift-on-raspberry-pi-230094737
// Covert C driver code to Swift(https://github.com/torvalds/linux)
// HX711 reference: https://cdn.sparkfun.com/datasheets/Sensors/ForceFlex/hx711_english.pdf
extension GpioManager {
    func setupLoadSensor() {
        dataGpio.direction = .IN
        sckGpio.direction = .OUT
    }

    func observeLoad(isPlaced: Bool, completion: ((Bool) -> Void)) {
        if isPlaced {
            observeLoadPlaced {
                completion(isPlaced)
                observeLoad(isPlaced: !isPlaced, completion: completion)
            }
        } else {
            observeLoadRemoved {
                completion(isPlaced)
                observeLoad(isPlaced: !isPlaced, completion: completion)
            }
        }
    }

    func observeLoadRemoved(completion: (() -> Void)) {
        while(true) {
            sleep(1)

            if readWeight() > 30 { return }
            print("Baggage is removed from load sensor")
            Task {
                try await DataStore.shared.updateLoadStatus(isRemoved: true)
            }
            gpio21Led.value = 0
            observeLoadPlaced {
                completion()
            }
            break
        }
    }

    func observeLoadPlaced(completion: (() -> Void)) {
        while(true) {
            sleep(1)
            if readWeight() < 100  { return }
            print("Baggage is placed to load sensor")
            Task {
                try await DataStore.shared.updateLoadStatus(isRemoved: false)
            }
            completion()
            gpio21Led.value = 1
            observeLoadRemoved {
                completion()
            }
            break
        }
    }

    func calibration() {
        var count = 0
        var weightList: [Int] = []
        let countMax = 100
        while(count <= countMax) {
            count += 1
            sleep(1)
            let weight = readWeight()
            if weight < 300000 {
                weightList.append(Int(weight))
            }
        }
        print("avarage: \(weightList.reduce(0, +) / weightList.count)")
    }

    func readWeight() -> Double {
        sckGpio.value = 0
        var dataIn: UInt32 = 0
        for _ in 0..<24 {
            sckGpio.value = 1
            dataIn = (dataIn << 1) | UInt32(dataGpio.value)
            sckGpio.value = 0
        }
        // 0x7fffff(16777215) is Max value, 0x800000(8388608) is Min value
        let maxValue: UInt32 = 16777215
        let minValue: UInt32 = 8388608
        if (dataIn == maxValue || dataIn == minValue) { return 0 }

        var signedData: Int32 = 0
        if (Int32(dataIn & minValue) == 1) {
            signedData = Int32(((dataIn ^ maxValue) + 1))
        } else {
            signedData = Int32(dataIn)
        }
        return (Double(signedData) - defaultLoadValue) / refernceUnit
    }
}

// Motor
extension GpioManager {
    func switchMotor(enable: Bool) {
        motorGpio.value = enable ? 1 : 0
    }
}
