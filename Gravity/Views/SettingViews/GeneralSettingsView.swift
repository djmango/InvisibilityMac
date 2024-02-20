//
//  GeneralSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import KeyboardShortcuts
import LaunchAtLogin
import OSLog
import SwiftData
import SwiftUI
import TelemetryClient

struct GeneralSettingsView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "GeneralSettingsView")

    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("analytics") private var analytics: Bool = true
    @AppStorage("betaFeatures") private var betaFeatures: Bool = false
    @AppStorage("emailAddress") private var emailAddress: String = ""
    @AppStorage("onboardingViewed") private var onboardingViewed = false

    @State private var showDeleteAllDataAlert: Bool = false

    @Query var messages: [Message]
    @Query var audios: [Audio]

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

                Section {
                    Button("Reset Onboarding") {
                        onboardingViewed = false
                    }
                    .bold()
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
                    Text("Wipe all data")
                        .foregroundColor(.red)
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
                .confirmationDialog(
                    AppMessages.wipeAllDataTitle,
                    isPresented: $showDeleteAllDataAlert
                ) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) { wipeAllData() }
                } message: {
                    Text(AppMessages.wipeAllDataMessage)
                }
                .dialogSeverity(.critical)
            }
            .padding(.trailing, 10)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .focusable(false)
    }

    private func wipeAllData() {
        logger.debug("Deleting all data...")

        // Analytics
        TelemetryManager.send("ApplicationWiped")

        let context = SharedModelContainer.shared.mainContext
        for message in messages {
            logger.debug("Deleting message: \(message.content ?? "")")
            context.delete(message)
        }
        for audio in audios {
            logger.debug("Deleting audio: \(audio.name)")
            context.delete(audio)
        }

        // Reset settings
        autoLaunch = false
        analytics = true
        betaFeatures = false
        emailAddress = ""

        // Reset onboarding
        onboardingViewed = false

        // Wipe models
        WhisperManager.shared.wipe()

        // Restart app
        NSApplication.shared.terminate(self)
    }
}
