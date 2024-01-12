//
//  AppDelegate.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/2/24.
//

import Cocoa
import Combine
import Foundation
import OllamaKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var timer: Timer?
    private var isAppActive = false
    private var generation: AnyCancellable?

    // This is the keepwarm for the LLM
    // Active while the app is active

    @AppStorage("selectedModel") private var selectedModel = "mistral:latest"

    func applicationDidFinishLaunching(_: Notification) {
        // Set up the observer for when the app becomes active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)

        // Set up the observer for when the app resigns active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidResignActive), name: NSApplication.didResignActiveNotification, object: nil)

        // Initialize the timer
        timer = Timer.scheduledTimer(
            timeInterval: 60,
            target: self,
            selector: #selector(sendApiCall),
            userInfo: nil,
            repeats: true
        )

        sendApiCall(forced: true)
    }

    @objc func appDidBecomeActive(notification _: NSNotification) {
        isAppActive = true
        print("App became active")
        sendApiCall(forced: true)
    }

    @objc func appDidResignActive(notification _: NSNotification) {
        isAppActive = false
        print("App became inactive")
    }

    @objc func sendApiCall(forced: Bool = false) {
        guard isAppActive || forced else { return }

        // print("Sending API call")
        Task {
            if await OllamaKit.shared.reachable() {
                guard let message = Message(content: "Say nothing", role: .user).toChatMessage() else { return }
                let data = OKChatRequestData(
                    model: selectedModel,
                    messages: [message]
                )

                // print("Sending data \(data)")
                generation = OllamaKit.shared.chat(data: data)
                    .sink( // This should never really trigger cuz we cancel right away, this is just to keep memory warm
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                print("Success completion")
                            case let .failure(error):
                                print("Failure completion \(error)")
                            }
                        },
                        receiveValue: { response in
                            print("Received response \(response)")
                        }
                    )
                // print("Cancelling generation")
                generation?.cancel()
            }
        }
    }

    func applicationWillTerminate(_: Notification) {
        print("App will terminate")
        timer?.invalidate()
        OllamaKit.shared.terminateBinaryProcess()
    }
}
