//
//  AudioWidgetView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import OSLog
import Pow
import SwiftData
import SwiftUI

struct AudioWidgetView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "AudioWidgetView")
    @Environment(\.colorScheme) var colorScheme

    private let audio: Audio

    init(audio: Audio) {
        self.audio = audio
    }

    var showProgress: Bool {
        audio.message?.status != .error && audio.message?.status != .complete && audio.message?.progress != 1.0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)

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
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .buttonStyle(.plain)
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
        .padding(.horizontal, 10)
        .padding(.bottom, 5)
        // .onTapGesture {
        //     tapAction()
        // }
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
