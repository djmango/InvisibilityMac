//
//  AppDelegate.swift
//  piedpiper
//
//  Created by Sulaiman Ghori on 1/2/24.
//

import Foundation
import OllamaKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_: Notification) {
        print("App will terminate")
        OllamaKit.shared.terminateBinaryProcess()
    }
}
