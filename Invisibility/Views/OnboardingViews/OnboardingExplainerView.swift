//
//  OnboardingExplainerView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import AVKit
import KeyboardShortcuts
import SwiftUI

struct OnboardingExplainerView: View {
    private var callback: () -> Void

    let videoNames = ["summon", "screenshot"]

    init(callback: @escaping () -> Void = {}) {
        self.callback = callback
    }

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    VideoPlayerView(videoName: "summon")
                        .frame(width: 285, height: 240)
                        .padding()

                    VStack {
                        Text("Summon")
                            .font(Font.custom("SF Pro Rounded", size: 30))
                            .foregroundColor(.white)
                            .padding()

                        KeyboardShortcuts.Recorder(for: .summon)
                            .labelsHidden()
                    }

                    Spacer()
                }
                Spacer()
            }
            .padding(.leading, 100)
            .padding(.top, 40)

            VStack {
                Spacer()
                HStack {
                    Spacer()

                    VStack {
                        Text("Screenshot")
                            .font(Font.custom("SF Pro Rounded", size: 30))
                            .foregroundColor(.white)
                            .padding()

                        KeyboardShortcuts.Recorder(for: .screenshot)
                            .labelsHidden()
                    }

                    VideoPlayerView(videoName: "screenshot")
                        .frame(width: 355, height: 240)
                        .padding()
                }
            }
            .padding(.trailing, 15)
            .padding(.bottom, 80)

            VStack {
                Spacer()
                Button(action: {
                    callback()
                }) {
                    VStack {
                        Image(systemName: "arrowshape.right.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white, lineWidth: 2)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .opacity(0.85)
                .buttonStyle(.plain)
                .transition(
                    .asymmetric(
                        insertion: .movingParts.move(
                            angle: .degrees(270)
                        ).combined(with: .movingParts.blur).combined(with: .opacity),
                        removal: .movingParts.blur.combined(with: .opacity)
                    )
                )
                .conditionalEffect(.repeat(.jump(height: 10), every: .seconds(3)), condition: true)
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            KeyboardShortcuts.setShortcut(.init(.g, modifiers: [.command]), for: .summon)
            KeyboardShortcuts.setShortcut(.init(.one, modifiers: [.command, .shift]), for: .screenshot)
        }
    }
}

struct VideoPlayerView: View {
    let videoName: String

    var body: some View {
        let player = AVPlayer(url: Bundle.main.url(forResource: videoName, withExtension: "mp4")!)
        player.actionAtItemEnd = .none

        return VideoPlayer(player: player)
            .onAppear {
                player.play()
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            }
            .onDisappear {
                player.pause()
                NotificationCenter.default.removeObserver(self)
            }
            .edgesIgnoringSafeArea(.all)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(radius: 10)
    }
}
