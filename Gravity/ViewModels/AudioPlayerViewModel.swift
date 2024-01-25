//
//  AudioPlayerViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import AVFoundation
import Foundation
import SwiftUI

class AudioPlayerViewModel: ObservableObject {
    // LIQUID DNB AND JUSTICE SPACE OPERA MADE THIS POSSIBLE
    static let shared = AudioPlayerViewModel()

    @Published var audio: Audio?
    @Published var player: AVAudioPlayer?
    @Published var currentTime: TimeInterval = 0
    @Published private(set) var isPlaying: Bool = false

    private var timer: Timer?

    private init() {}

    func prepare() {
        guard let audio else { return }
        do {
            player = try AVAudioPlayer(data: audio.audioFile)
            player?.prepareToPlay()
            startTimer()
            updatePlayingStatus()
        } catch {
            AlertManager.shared.doShowAlert(
                title: "Error",
                message: "Could not prepare audio: \(error.localizedDescription)"
            )
        }
    }

    func play() {
        guard let audio else { return }
        do {
            player = try AVAudioPlayer(data: audio.audioFile)
            player?.play()
            startTimer()
            updatePlayingStatus()
        } catch {
            AlertManager.shared.doShowAlert(
                title: "Error",
                message: "Could not play audio: \(error.localizedDescription)"
            )
        }
    }

    func stop() {
        player?.stop()
        player = nil
        audio = nil
        updatePlayingStatus()
        stopTimer()
    }

    func pause() {
        player?.pause()
        updatePlayingStatus()
    }

    func resume() {
        player?.play()
        updatePlayingStatus()
    }

    func playOrResume() {
        if player == nil {
            play()
        } else {
            resume()
        }
    }

    func seek(to time: TimeInterval) {
        // If not playing, start playing.
        if player == nil {
            prepare()
        }
        player?.currentTime = time
        player?.play()

        updatePlayingStatus()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.currentTime = self?.player?.currentTime ?? 0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updatePlayingStatus() {
        isPlaying = player?.isPlaying ?? false
    }
}
