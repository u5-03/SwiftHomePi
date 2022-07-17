//
//  DeviceCall.swift
//  
//
//  Created by yugo.sugiyama on 2022/08/29.
//

import Foundation
import Alamofire
import SwiftHomeCredentials

struct DeviceCall {
    static func postSwitchBot(interval: UInt32) {
        let token = SwiftHomeCredentials.switchBotToken
        let headers: Alamofire.HTTPHeaders = [
            .accept("*/*"),
            .authorization(token),
            .contentType("application/json"),
            .acceptCharset("utf8")
        ]
        let parameter = [
            "command": "turnOn",
            "parameter": "default",
            "commandType": "command",
        ]
        SwitchBotDevices.allCases.forEach { device in
            let urlString = "https://api.switch-bot.com/v1.0/devices/\(device.deviceId)/commands"
            print(urlString)
            AF.request(urlString,
                       method: .post,
                       parameters: parameter,
                       encoding: JSONEncoding.default,
                       headers: headers
            )
            .responseDecodable(of: Empty.self) { response in
                switch response.result {
                case .success:
                    print("Success")
                case .failure(let error):
                    print(error)
                }
            }
            sleep(interval)
        }
    }
}
