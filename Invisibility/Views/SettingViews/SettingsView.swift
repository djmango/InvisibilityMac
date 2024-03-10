//
//  SettingsView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/4/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import FluidGradient
import KeyboardShortcuts
import LaunchAtLogin
import OSLog
import SwiftUI

struct SettingsView: View {
    private let logger = Logger(subsystem: "so.invisibility.app", category: "SettingsView")
    let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("onboardingViewed") private var onboardingViewed = false

    @ObservedObject private var updaterViewModel = UpdaterViewModel.shared
    @ObservedObject private var userManager = UserManager.shared

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VStack(alignment: .center) {
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
                    // .background(
                    //     FluidGradient(
                    //         blobs: [.blue, .teal, .indigo],
                    //         highlights: [.blue, .teal, .indigo],
                    //         speed: 0.5,
                    //         blur: 0
                    //     )
                    //     .blur(radius: 70)
                    //     .background(.quaternary)
                    //     .clipShape(RoundedRectangle(cornerRadius: 10))
                    // )
                )
                .shadow(radius: colorScheme == .dark ? 2 : 0)
                .visible(if: userManager.user != nil)
                .padding(.top, 20)

                Button(action: {
                    UserManager.shared.login()
                }) {
                    Text("Login")
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 10)
                .visible(if: userManager.user == nil)

                Divider()
                    .padding(.horizontal, 100)
                    .padding(.bottom, 10)

                HStack {
                    Text("Launch at Login:")
                    LaunchAtLogin.Toggle()
                        .labelsHidden()
                }
                .padding(.bottom, 10)

                HStack {
                    Text("Toggle panel")
                    KeyboardShortcuts.Recorder(for: .summon)
                }

                HStack {
                    Text("Screenshot:")
                    KeyboardShortcuts.Recorder(for: .screenshot)
                }
                .padding(.bottom, 10)

                Button("Reset Onboarding") {
                    onboardingViewed = false
                    OnboardingManager.shared.startOnboarding()
                }

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
                    .padding(.vertical, 5)
            }
        }
        .frame(minWidth: 500, minHeight: 550)
        .focusable(false)
        .background(
            // FluidGradient(blobs: [.red, .blue],
            //               highlights: [.yellow, .orange, .purple],
            //               speed: 0.3,
            //               blur: 0.75)
            //     .background(.quaternary)
            // LinearGradient(
            //     gradient: Gradient(colors: [Color("InvisGrad1"), Color("InvisGrad2")]),
            //     startPoint: .topLeading,
            //     endPoint: .bottomTrailing
            // )
        )
    }
}
