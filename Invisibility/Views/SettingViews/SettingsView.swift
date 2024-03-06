//
//  SettingsView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/4/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import KeyboardShortcuts
import LaunchAtLogin
import OSLog
import SwiftData
import SwiftUI

struct SettingsView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "SettingsView")
    let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("onboardingViewed") private var onboardingViewed = false

    @ObservedObject private var updaterViewModel = UpdaterViewModel.shared
    @ObservedObject private var userManager = UserManager.shared

    @State private var showDeleteAllDataAlert: Bool = false

    @Query var messages: [Message]
    @Query var audios: [Audio]

    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                // User profile pic and login/logout button
                HStack {
                    Spacer()
                    // Profile pic from url
                    VStack {
                        AsyncImage(url: URL(string: userManager.user?.profilePictureUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 10)
                                .padding(10)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 10)
                                .padding(10)
                        }
                        .visible(if: userManager.user?.profilePictureUrl != nil)

                        Text(userManager.user?.email ?? "")
                            .font(.headline)
                            .padding(.bottom, 5)

                        Text("\(userManager.user?.firstName ?? "") \(userManager.user?.lastName ?? "")")
                            .font(.headline)
                            .padding(.bottom, 5)
                            .visible(if: userManager.user?.firstName != nil || userManager.user?.lastName != nil)

                        Button(action: {
                            UserManager.shared.logout()
                        }) {
                            Text("Logout")
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()
                }
                .visible(if: userManager.user != nil)
                .padding(.vertical, 10)

                HStack {
                    Spacer()
                    Button(action: {
                        UserManager.shared.login()
                    }) {
                        Text("Login")
                    }
                    .buttonStyle(.bordered)
                    .padding(.trailing, 10)
                    Spacer()
                }
                .padding(.bottom, 10)
                .visible(if: userManager.user == nil)

                LaunchAtLogin.Toggle()
                    .padding(.bottom, 10)

                HStack {
                    Text("Summon Invisibility:")
                    KeyboardShortcuts.Recorder(for: .summon)
                }

                HStack {
                    Text("Screenshot:")
                    KeyboardShortcuts.Recorder(for: .screenshot)
                }
                .padding(.bottom, 10)

                Button("Reset Onboarding") {
                    onboardingViewed = false
                }

                Spacer()

                Image("AppIconBitmap")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .padding(.vertical, 10)

                HStack(spacing: 0) {
                    Text("Founded by ")
                        .font(.headline)
                    Text("Sulaiman Ghori")
                        .font(.headline)
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .onTapGesture {
                            if let url = URL(string: "https://x.com/sulaimanghori") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    Text(" and ")
                        .font(.headline)
                    Text("Tye Daniel")
                        .font(.headline)
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .onTapGesture {
                            if let url = URL(string: "https://x.com/TyeDan") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                }

                HStack {
                    Button("Feedback") {
                        if let url = URL(string: "mailto:sulaiman@invisibility.so") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Acknowledgments") {
                        if let url = URL(string: "https://github.com/InvisibilityInc/Invisibility/tree/master/LICENSES") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Check for Updates") {
                        updaterViewModel.updater.checkForUpdates()
                    }
                    .buttonStyle(.bordered)

                    Button("Privacy") {
                        if let url = URL(string: "https://invisibility.so/privacy") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 10)

                Text("© 2024 Invisibility, Inc. All rights reserved. Version \(bundleVersion)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }

            // VStack {
            //     Spacer()
            //     HStack {
            //         Spacer()
            //         Button(action: {
            //             showDeleteAllDataAlert = true
            //         }) {
            //             Text("Wipe all data")
            //                 .foregroundColor(.red)
            //             Image(systemName: "trash")
            //                 .foregroundColor(.red)
            //         }
            //         .buttonStyle(.plain)
            //         .onHover { hovering in
            //             if hovering {
            //                 NSCursor.pointingHand.push()
            //             } else {
            //                 NSCursor.pop()
            //             }
            //         }
            //         .confirmationDialog(
            //             AppMessages.wipeAllDataTitle,
            //             isPresented: $showDeleteAllDataAlert
            //         ) {
            //             Button("Cancel", role: .cancel) {}
            //             Button("Delete", role: .destructive) { wipeAllData() }
            //         } message: {
            //             Text(AppMessages.wipeAllDataMessage)
            //         }
            //         .dialogSeverity(.critical)
            //     }
            //     .padding(.trailing, 10)
            //     .padding(.bottom, 10)
            // }
        }
        .frame(minWidth: 500, minHeight: 500)
        .focusable(false)
    }

    private func wipeAllData() {
        logger.debug("Deleting all data...")

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
        showMenuBarExtra = true
        onboardingViewed = false

        // Wipe models
        WhisperManager.shared.wipe()

        // Restart app
        NSApplication.shared.terminate(self)
    }
}
