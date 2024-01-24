//
//  GeneralSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import KeyboardShortcuts
import LaunchAtLogin
import OllamaKit
import os
import SwiftData
import SwiftUI

struct GeneralSettingsView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "GeneralSettingsView")

    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("analytics") private var analytics: Bool = true
    @AppStorage("betaFeatures") private var betaFeatures: Bool = false
    @AppStorage("emailAddress") private var emailAddress: String = ""
    @AppStorage("onboardingViewed") private var onboardingViewed = false

    @State private var showDeleteAllDataAlert: Bool = false

    @Query var chats: [Chat]
    @Query var messages: [Message]
    @Query var ollamaModels: [OllamaModel]
    @Query var audios: [Audio]
    @Query var audioSegments: [AudioSegment]

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Form {
                Section {
                    HStack {
                        Text("Summon Gravity:").bold()
                        KeyboardShortcuts.Recorder(for: .summon)
                    }
                }

                LaunchAtLogin.Toggle().bold()

                Section {
                    Toggle("Share crash reports & analytics", isOn: $analytics).bold()
                }

                Section {
                    Toggle("Enable beta features", isOn: $betaFeatures).bold()
                }

                Section {
                    TextField("Email Address", text: $emailAddress)
                        .bold()
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 350)
                }
            }
            .frame(width: 500)
            .fixedSize()

            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showDeleteAllDataAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .padding()
                .confirmationDialog(
                    AppMessages.wipeAllDataTitle,
                    isPresented: $showDeleteAllDataAlert
                ) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        logger.debug("Deleting all data...")
                        let context = SharedModelContainer.shared.mainContext
                        for chat in chats {
                            logger.debug("Deleting chat: \(chat.name)")
                            context.delete(chat)
                        }
                        for message in messages {
                            logger.debug("Deleting message: \(message.content ?? "")")
                            context.delete(message)
                        }
                        for ollamaModel in ollamaModels {
                            logger.debug("Deleting ollamaModel: \(ollamaModel.name)")
                            context.delete(ollamaModel)
                        }
                        for audio in audios {
                            logger.debug("Deleting audio: \(audio.name ?? "")")
                            context.delete(audio)
                        }
                        for audioSegment in audioSegments {
                            logger.debug("Deleting audioSegment: \(audioSegment.text)")
                            context.delete(audioSegment)
                        }

                        // Reset settings
                        autoLaunch = false
                        analytics = true
                        betaFeatures = false
                        emailAddress = ""

                        // Reset onboarding
                        onboardingViewed = false

                        // Wipe models
                        OllamaViewModel.shared.wipeOllama()
                        WhisperViewModel.shared.wipeWhisper()

                        // Restart ollama
                        OllamaKit.shared.restart(minInterval: 0)

                        // Restart app
                        NSApplication.shared.terminate(self)
                    }
                } message: {
                    Text(AppMessages.wipeAllDataMessage)
                }
                .dialogSeverity(.critical)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .focusable(false)
    }
}
