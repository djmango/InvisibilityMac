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
import UniformTypeIdentifiers

struct SettingsView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "SettingsView")
    let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    @AppStorage("animateButtons") private var animateButtons = true
    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("betaFeatures") private var betaFeatures = false
    @AppStorage("onboardingViewed") private var onboardingViewed = false
    @AppStorage("shortcutHints") private var shortcutHints = true
    @AppStorage("showMenuBar") private var showMenuBar: Bool = true
    @AppStorage("llmModelName") private var llmModel = LLMModelRepository.claude3Opus.model.human_name

    @State private var showingExporter = false
    @State private var document: TextDocument = TextDocument(text: "")

    @ObservedObject private var userManager = UserManager.shared
    private var updaterViewModel = UpdaterViewModel.shared

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .menu, blendingMode: .withinWindow, cornerRadius: 16)

            ScrollView {
                VStack(alignment: .center, spacing: 10) {
                    Spacer()
                    // User profile pic and login/logout button
                    SettingsUserCardView()
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

                    Toggle("Show on Menu Bar", isOn: $showMenuBar)
                        .toggleStyle(.switch)

                    Toggle("Shortcut Hints", isOn: $shortcutHints)
                        .toggleStyle(.switch)

                    Toggle("Beta Features", isOn: $betaFeatures)
                        .toggleStyle(.switch)
                        .onChange(of: betaFeatures) {
                            if betaFeatures {
                            } else {
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

                    Picker("", selection: $llmModel) {
                        ForEach(LLMModelRepository.allModels, id: \.self) { model in
                            Text(model.human_name).tag(model.human_name)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 180)

                    Spacer()

                    Divider()
                        .padding(.horizontal, 80)

                    Spacer()

                    Grid {
                        GridRow {
                            Button("Reset Onboarding") {
                                onboardingViewed = false
                                OnboardingManager.shared.startOnboarding()
                            }
                            .buttonStyle(.bordered)

                            Button("Export Chat") {
                                let text = MessageViewModel.shared.messages.map { message in
                                    "\(message.role?.rawValue.capitalized ?? ""): \(message.text)"
                                }.joined(separator: "\n")
                                document = TextDocument(text: text)
                                showingExporter = true
                            }
                            .buttonStyle(.bordered)
                        }

                        GridRow {
                            Button("Check for Updates") {
                                updaterViewModel.updater.checkForUpdates()
                            }
                            .buttonStyle(.bordered)

                            Button("Feedback") {
                                if let url = URL(string: "mailto:support@i.inc") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Spacer()

                    HStack {
                        Button("Acknowledgments") {
                            if let url = URL(string: "https://github.com/InvisibilityInc/Invisibility/tree/master/LICENSES") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)

                        Button("Privacy") {
                            if let url = URL(string: "https://i.inc/privacy") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
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

                    Text("© 2024 Invisibility, Inc. All rights reserved. Version \(bundleVersion)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 5)
                }
                .animation(.easeIn, value: betaFeatures)
            }
            .scrollIndicators(.never)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .frame(maxWidth: 400)
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .shadow(radius: colorScheme == .dark ? 5 : 0)
        .fileExporter(
            isPresented: $showingExporter,
            document: document,
            contentType: .plainText,
            defaultFilename: "invisibility.txt"
        ) { result in
            switch result {
            case let .success(url):
                logger.info("Saved to \(url)")
            case let .failure(error):
                logger.error(error.localizedDescription)
            }
        }
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)
        return .init(regularFileWithContents: data!)
    }
}
