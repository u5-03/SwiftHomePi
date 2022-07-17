//
//  StatusStore.swift
//  
//
//  Created by yugo.sugiyama on 2022/08/30.
//

import Foundation

final class StatusStore {
    // home default value and offset
    private static let homeLatitude = 0.0
    private static let homeLongitude = 0.0
    private static let homeAltimeter = 0.0
    private static let allowableDifferenceLatitude = 0.0
    private static let allowableDifferenceLongtitude = 0.0
    private static let allowableDifferenceAltimeter = 0.0

    static var isAllAuthPassed: Bool {
        get async {
            let isInHome = await isInHome
            return isLoadPlaced && isSuicaAuthenticated
            && isInHome
        }
    }

    static var isLoadPlaced = false
    static var isSuicaAuthenticated = false
    static var isInHome: Bool {
        get async {
            guard let deviceInfo = try? await DataStore.shared.fetchDeviceInfo() else { return false }
            return abs(deviceInfo.deviceLatitude - homeLatitude) < allowableDifferenceLatitude
            && abs(deviceInfo.deviceLongitude - homeLongitude) < allowableDifferenceLatitude
            && abs(deviceInfo.absoluteAltimeter - homeAltimeter) < allowableDifferenceAltimeter
        }
    }
}
