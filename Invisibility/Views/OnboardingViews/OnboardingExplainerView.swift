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

    let summonPlayer = AVPlayer(url: Bundle.main.url(forResource: "shortcuts", withExtension: "mp4")!)
    let screenshotPlayer = AVPlayer(url: Bundle.main.url(forResource: "screenshot", withExtension: "mp4")!)

    init(callback: @escaping () -> Void = {}) {
        self.callback = callback
        self.summonPlayer.actionAtItemEnd = .none
        self.screenshotPlayer.actionAtItemEnd = .none
    }

    var body: some View {
        VStack {
            HStack {
                VStack {
                    VideoPlayer(player: summonPlayer)
                        .onAppear {
                            summonPlayer.play()
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: summonPlayer.currentItem, queue: .main) { _ in
                                summonPlayer.seek(to: .zero)
                                summonPlayer.play()
                            }
                        }
                        .onDisappear {
                            summonPlayer.pause()
                            NotificationCenter.default.removeObserver(self)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(radius: 10)
                        .frame(width: 425, height: 240)
                        .padding()

                    Text("Toggle panel")
                        .font(Font.custom("SF Pro Rounded", size: 30))
                        .foregroundColor(.white)
                        .padding()

                    KeyboardShortcuts.Recorder(for: .summon)
                        .labelsHidden()

                    Spacer()
                }
                .padding(.top, 40)
                .padding(.leading, 100)

                Spacer()

                VStack {
                    Spacer()
                    Text("Screenshot")
                        .font(Font.custom("SF Pro Rounded", size: 30))
                        .foregroundColor(.white)
                        .padding()

                    KeyboardShortcuts.Recorder(for: .screenshot)
                        .labelsHidden()
                        .padding(.bottom, 20)

                    VideoPlayer(player: screenshotPlayer)
                        .onAppear {
                            screenshotPlayer.play()
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: screenshotPlayer.currentItem, queue: .main) { _ in
                                screenshotPlayer.seek(to: .zero)
                                screenshotPlayer.play()
                            }
                        }
                        .onDisappear {
                            screenshotPlayer.pause()
                            NotificationCenter.default.removeObserver(self)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(radius: 10)
                        .frame(width: 355, height: 240)
                        .padding()
                }
                .padding(.bottom, 20)
                .padding(.trailing, 50)
            }
            .padding(.top, 20)

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
                .keyboardShortcut(.defaultAction)
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
