//
//  AudioWidgetView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import OSLog
import Pow
import SwiftData
import SwiftUI

struct AudioWidgetView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "AudioWidgetView")
    @Environment(\.colorScheme) var colorScheme

    private let audio: Audio
    private let tapAction: () -> Void

    init(audio: Audio, tapAction: @escaping () -> Void) {
        self.audio = audio
        self.tapAction = tapAction
    }

    var showProgress: Bool {
        audio.message?.status != .error && audio.message?.status != .complete && audio.message?.progress != 1.0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color("WidgetColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                )

            HStack {
                Spacer()

                VStack(alignment: .center) {
                    Spacer()

                    // If we are done generating, show the name of the audio
                    let name = audio.name.isEmpty ? "Generating title.." : audio.name
                    Text(name)
                        .font(.title2)
                        .padding()
                        .bold()
                        .hide(if: audio.status != .complete, removeCompletely: true)

                    // Button to draft an email
                    Button(action: { emailAction() }) {
                        Image(systemName: "envelope.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .padding(5)
                            .foregroundColor(.white)

                        Text("Draft Email")
                            .font(.title3)
                            .bold()
                            .padding(5)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color("AccentColorGradient1")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8)
                    .padding(.bottom, 3)
                    .padding(.horizontal, 10)
                    .focusable(false)
                    .onTapGesture {
                        emailAction()
                    }
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .hide(if: showProgress, removeCompletely: true)

                    // Show the last segment text with an animation on change
                    Text(audio.segments.last?.text ?? "")
                        .font(.title3)
                        .padding()
                        .bold()
                        .italic()
                        .animation(.snappy, value: audio.segments.last?.text ?? "")
                        .hide(if: audio.status == .complete, removeCompletely: true)

                    Spacer()

                    Text("\(audio.message?.status?.description ?? "Processing")..")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.gray)
                        .padding(.bottom, 3)
                        .hide(if: !showProgress, removeCompletely: true)

                    ProgressView(value: audio.message?.progress, total: 1.0)
                        .accentColor(.accentColor)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .cornerRadius(10)
                        // .frame(width: 400, height: 10)
                        .conditionalEffect(
                            .repeat(
                                .glow(color: .white, radius: 10),
                                every: 3
                            ), condition: showProgress
                        )
                        .hide(if: !showProgress, removeCompletely: true)
                }

                Spacer()
            }
        }
        .onTapGesture {
            tapAction()
        }
    }

    /// Draft an email with the audio
    func emailAction() {
        guard let message = audio.message else {
            logger.error("Audio message not found")
            AlertManager.shared.doShowAlert(
                title: "Error",
                message: "Audio message not found"
            )
            return
        }

        Task {
            await message.generateEmail(open: true)
        }
    }
}
