//
//  VoiceRecorder.swift
//  Invisibility
//
//  Created by Braeden Hall on 7/4/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import Speech
import PostHog
import Speech
import SwiftUI


@MainActor
class VoiceRecorder: ObservableObject {
    static let shared = VoiceRecorder()
    
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "ScreenRecorder")

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var isSetup = false
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// This is a hack to update the text field rendering when the text is cleared
    @Published public var clearToggle: Bool = false
    
    @Published var isRunning = false
    @Published var transcribedText: String = ""

    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }

            switch authStatus {
                case .authorized:
                    logger.info("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    logger.error("Speech recognition not authorized")
                @unknown default:
                    logger.error("Unknown authorization status")
            }
        }
    }

    func toggleRecording() {
        if isRunning {
            Task {
                await stop(shouldClearText: false)
            }
        } else {
            Task {
                await start()
            }
        }
    }

    /// Starts capturing voice content.
    func start() async {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        guard !isRunning else { return }
        defer { PostHogSDK.shared.capture("start_stt") }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            logger.error("audioEngine couldn't start due to an error.")
        }

        withAnimation(AppConfig.snappy) {
            isRunning = true
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                
                if !text.isEmpty && isRunning {
                    transcribedText = text
                }
            }

            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRunning = false
            }
        }
    }

    /// Stops capturing voice content.
    func stop(shouldClearText: Bool) async {
        guard isRunning else { return }
        defer { PostHogSDK.shared.capture("stop_stt") }

        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        
        if (shouldClearText) {
            transcribedText = ""
        }
        
        withAnimation(AppConfig.snappy) {
            isRunning = false
        }
    }
}
