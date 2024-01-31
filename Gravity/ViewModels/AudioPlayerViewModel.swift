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
    @Published private(set) var isPlaying: Bool = false

    private init() {}

    func prepare() {
        guard let audio else { return }
        do {
            player = try AVAudioPlayer(data: audio.audioFile)
            player?.prepareToPlay()
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

    private func updatePlayingStatus() {
        isPlaying = player?.isPlaying ?? false
    }
}
