//
//  FirebaseManager.swift
//  
//
//  Created by yugo.sugiyama on 2022/09/08.
//

import Foundation
import Alamofire
import SwiftHomeCredentials

// FCM(Regacy API) https://firebase.google.com/docs/cloud-messaging/ios/client?hl=ja
final class FirebaseManager {
    static func sendMessage() {
        let serverKey = SwiftHomeCredentials.fcmServerKey
        // This is demo app, so fmc token must be set manually.
        let fmcToken = "xxxxxxxx"

        let headers: Alamofire.HTTPHeaders = [
            .accept("*/*"),
            .contentType("application/json"),
            .acceptCharset("utf8"),
            .authorization("key=\(serverKey)")
        ]
        let parameter = [
            "registration_ids": [
                fmcToken
            ],
            "notification": [
                "title": "侵入者通知⚠️",
                "body": "家への侵入者を検知しました！カメラを確認してください！",
                "badge": "0",
            ]
        ] as [String : Any]
        let urlString = "https://fcm.googleapis.com/fcm/send"
        AF.request(urlString,
                   method: .post,
                   parameters: parameter,
                   encoding: JSONEncoding.default,
                   headers: headers
        )
        .responseString(completionHandler: { response in
            print(response)
        })
    }
}
