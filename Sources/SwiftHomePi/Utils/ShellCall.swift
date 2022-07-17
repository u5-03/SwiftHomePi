//
//  ShellCall.swift
//  
//
//  Created by yugo.sugiyama on 2022/08/18.
//

import Foundation
import PathKit

struct ShellCall {
    // Ref: https://ja.stackoverflow.com/q/65654
    func playWarningSound() {
        let command: String
        let path: String
        #if os(Linux)
        command = "/usr/bin/mpg123"
        // If on linux, `Path.current` returns repository path
        path = "\(Path.current)/Sources/SwiftHomePi"
        #else
        command = "/opt/homebrew/bin/mpg123"
        // If on Mac, `Path.current` returns DerivedData path
        path = "\(Path.current)/SwiftHomePi_SwiftHomePi.bundle/Contents/Resources"
        #endif
        let voicePath = "\(path)/warning_voice.mp3"

        do {
            try shell(command, voicePath)
        } catch {
            print(error)
        }
    }

    @discardableResult
    func shell(_ args: String...) throws ->  Int32 {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = args
        try task.run()
        task.waitUntilExit()
        return task.terminationStatus
    }
}
