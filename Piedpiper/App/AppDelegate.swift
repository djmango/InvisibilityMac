//
//  AppDelegate.swift
//  piedpiper
//
//  Created by Sulaiman Ghori on 1/2/24.
//

import Foundation
import SwiftUI
import OllamaKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ aNotification: Notification) {
        print("App will terminate")
        OllamaKit.shared.terminateBinaryProcess()
    }
}
