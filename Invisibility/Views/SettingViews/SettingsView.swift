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
import SwiftUI

struct SettingsView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "SettingsView")
    let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    @AppStorage("animateButtons") private var animateButtons = true
    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("betaFeatures") private var betaFeatures = false
    @AppStorage("onboardingViewed") private var onboardingViewed = false
    @AppStorage("shortcutHints") private var shortcutHints = true
    @AppStorage("showMenuBar") private var showMenuBar: Bool = true

    @ObservedObject private var llmManager = LLMManager.shared
    @ObservedObject private var updaterViewModel = UpdaterViewModel.shared
    @ObservedObject private var userManager = UserManager.shared

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                // User profile pic and login/logout button
                VStack(alignment: .center) {
                    AsyncImage(url: URL(string: userManager.user?.profilePictureUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .padding(10)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    .visible(if: userManager.user?.profilePictureUrl != nil)

                    Text("\(userManager.user?.firstName ?? "") \(userManager.user?.lastName ?? "")")
                        .font(.title3)
                        .visible(if: userManager.user?.firstName != nil || userManager.user?.lastName != nil)

                    Text(userManager.user?.email ?? "")
                        .font(.caption)
                        .padding(.bottom, 15)

                    Text("Invisibility Plus")
                        .font(.caption)
                        .italic()
                        .visible(if: userManager.isPaid)

                    Button(action: {
                        UserManager.shared.manage()
                    }) {
                        Text("Manage")
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        UserManager.shared.logout()
                    }) {
                        Text("Logout")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("ChatButtonBackgroundColor"))
                        .stroke(Color.white, lineWidth: 1)
                )
                .shadow(radius: colorScheme == .dark ? 2 : 0)
                .visible(if: userManager.user != nil)

                Button(action: {
                    UserManager.shared.login()
                }) {
                    Text("Login")
                }
                .buttonStyle(.bordered)
                .visible(if: userManager.user == nil, removeCompletely: true)

                Spacer()

                Divider()
                    .padding(.horizontal, 80)

                Spacer()

                HStack {
                    Text("Toggle panel")
                    KeyboardShortcuts.Recorder(for: .summon)
                }

                HStack {
                    Text("Screenshot")
                    KeyboardShortcuts.Recorder(for: .screenshot)
                }

                LaunchAtLogin.Toggle("Launch at Login")
                    .toggleStyle(.switch)

                Toggle("Show Menu Bar", isOn: $showMenuBar)
                    .toggleStyle(.switch)

                Toggle("Shortcut Hints", isOn: $shortcutHints)
                    .toggleStyle(.switch)

                Toggle("Beta Features", isOn: $betaFeatures)
                    .toggleStyle(.switch)
                    .onChange(of: betaFeatures) {
                        if betaFeatures {
                            logger.info("Beta features enabled")
                        } else {
                            logger.info("Beta features disabled")
                            // Reset beta features
                            animateButtons = true
                        }
                    }

                Divider()
                    .padding(.horizontal, 150)
                    .visible(if: betaFeatures, removeCompletely: true)

                Toggle("Animate Buttons", isOn: $animateButtons)
                    .toggleStyle(.switch)
                    .visible(if: betaFeatures, removeCompletely: true)

                Picker("", selection: $llmManager.model) {
                    Text("Claude-3 Opus").tag(LLMModels.claude3_opus)
                    // Text("Gemini Pro").tag(LLMModels.gemini_pro)
                    Text("GPT-4").tag(LLMModels.gpt4)
                }
                .pickerStyle(.palette)
                .frame(maxWidth: 200)
                .visible(if: betaFeatures, removeCompletely: true)

                Spacer()

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

                Button("Reset Onboarding") {
                    onboardingViewed = false
                    OnboardingManager.shared.startOnboarding()
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

                Image("MenuBarIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .padding(.bottom, -5)
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://invisibility.so") {
                            NSWorkspace.shared.open(url)
                        }
                    }

                Text("© 2024 Invisibility, Inc. All rights reserved. Version \(bundleVersion)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            .animation(.easeIn, value: betaFeatures)
        }
        .frame(minWidth: 500, minHeight: 750)
        .focusable(false)
    }
}
