//
//  OnboardingView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import AVFoundation
import FluidGradient
import OSLog
import SwiftUI

struct OnboardingView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "OnboardingView")
    @State private var viewIndex: Int = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var fluidSpeed: CGFloat = 0.50

    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, cornerRadius: 0)
                .ignoresSafeArea()

            FluidGradient(
                blobs: [.blue, .teal, .indigo],
                highlights: [.blue, .teal, .indigo],
                speed: fluidSpeed,
                blur: 0
            )
            .blur(radius: 70)
            .background(.quaternary)
            .ignoresSafeArea()

            switch viewIndex {
            case 0:
                OnboardingIntroView {
                    viewIndex = 1
                    fluidSpeed = 0.30
                }

            case 1:
                OnboardingExplainerView { viewIndex = 2 }

            case 2:
                OnboardingAccountView { viewIndex = 3 }

            default:
                EmptyView()
            }
        }
        .animation(.snappy, value: viewIndex)
        .onAppear {
            if !onboardingViewed {
                // play()
            }
        }
    }

    func play() {
        guard let url = Bundle.main.url(forResource: "invis_launch", withExtension: "mp3") else {
            logger.error("Sound file not found.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            logger.error("Failed to play sound. Error: \(error)")
        }
    }
}
