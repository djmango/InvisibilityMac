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
    @AppStorage("llmModelName") public var llmModel = LLMModelRepository.shared.models[0].id
    @AppStorage("dynamicLLMLoad") private var dynamicLLMLoad = false

    // TODO: func to reset to default settings

    @State private var showingExporter = false
    @State private var document: TextDocument = TextDocument(text: "")

    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var settingsViewModel = SettingsViewModel.shared
    private var userManager = UserManager.shared
    private var mainWindowViewModel = MainWindowViewModel.shared
    private var updaterViewModel = UpdaterViewModel.shared
    private var llmModelRepository = LLMModelRepository.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                // User profile pic and login/logout button
                SettingsUserCardView()
                    .visible(if: settingsViewModel.user != nil)

                Button(action: {
                    UserManager.shared.login()
                }) {
                    Text("Login")
                }
                .buttonStyle(.bordered)
                .visible(if: settingsViewModel.user == nil, removeCompletely: true)
                .onHover { hovered in
                    if hovered {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }

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
                    .onHover { hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }

                Toggle("Show on Menu Bar", isOn: $showMenuBar)
                    .toggleStyle(.switch)
                    .onHover { hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }

                Toggle("Shortcut Hints", isOn: $shortcutHints)
                    .toggleStyle(.switch)
                    .onHover { hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }

                Toggle("Beta Features", isOn: $betaFeatures)
                    .toggleStyle(.switch)
                    .onChange(of: betaFeatures) {
                        if betaFeatures {
                        } else {
                            // Reset beta features
                            animateButtons = true
                        }
                    }
                    .onHover { hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }

                Divider()
                    .padding(.horizontal, 150)
                    .visible(if: betaFeatures, removeCompletely: true)

                Toggle("Animate Buttons", isOn: $animateButtons)
                    .toggleStyle(.switch)
                    .visible(if: betaFeatures, removeCompletely: true)
                    .onHover { hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }

                Toggle("All LLMs", isOn: $dynamicLLMLoad)
                    .toggleStyle(.switch)
                    .visible(if: betaFeatures, removeCompletely: true)
                    .onChange(of: dynamicLLMLoad) {
                        Task { await llmModelRepository.loadDynamicModels() }
                    }
                    .onHover { hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }

                Picker("", selection: $llmModel) {
                    ForEach(settingsViewModel.availableLLMModels, id: \.self) { model in
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
                        .onHover { hovered in
                            if hovered {
                                NSCursor.pointingHand.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }

                        Button("Export Chat") {
                            let text = MessageViewModel.shared.api_messages_in_chat.map { message in
                                "\(message.role.rawValue.capitalized): \(message.text)"
                            }.joined(separator: "\n")
                            document = TextDocument(text: text)
                            showingExporter = true
                        }
                        .buttonStyle(.bordered)
                        .onHover { hovered in
                            if hovered {
                                NSCursor.pointingHand.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
                    }

                    GridRow {
                        Button("Check for Updates") {
                            updaterViewModel.updater.checkForUpdates()
                        }
                        .buttonStyle(.bordered)
                        .onHover { hovered in
                            if hovered {
                                NSCursor.pointingHand.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }

                        Button("Feedback") {
                            if let url = URL(string: "mailto:support@i.inc") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        .onHover { hovered in
                            if hovered {
                                NSCursor.pointingHand.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
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
                    .onHover { hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }

                    Button("Privacy") {
                        if let url = URL(string: "https://i.inc/privacy") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                    .onHover { hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .overlay(
            VStack {
                HStack {
                    Button(action: {
                        _ = mainWindowViewModel.changeView(to: .chat)
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.chatButtonForeground)
                    }
                    .buttonStyle(.plain)
                    .padding()

                    Spacer()
                }
                Spacer()
            }
        )
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .padding(.bottom, 3)
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
